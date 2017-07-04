//
//  Processor.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Dispatch
import Redis

public final class Processor: RouterDelegate {
    private static let mutex = Mutex()
    private static var _workerState = [Tid: WorkerState]()

    static var workerStates: [Tid: WorkerState] {
        return mutex.synchronize { return _workerState }
    }

    static func updateState(_ value: WorkerState?, for tid: Tid) {
        mutex.synchronize { _workerState[tid] = value }
    }

    static var processedCounter = AtomicCounter<Int>(0)
    static var failureCounter = AtomicCounter<Int>(0)

    let dispatchQueue: DispatchQueue
    private var looper: DispatchWorkItem!
    
    var connectionPool = AnyConnectablePool(Application.default.connectionPool)
    
    // property
    let index: Int
    let fetcher: Fetcher
    let router: Routable
    var job: UnitOfWork?
    weak var delegate: ProcessorLifecycleDelegate!

    // flags to control
    private let down = AtomicProperty<Bool>(false)
    private let done = AtomicProperty<Bool>(false)

    init(index: Int,
         fetcher: Fetcher,
         router: Routable,
         dispatchQueue: DispatchQueue,
         delegate: ProcessorLifecycleDelegate) {
        self.index = index
        self.fetcher = fetcher
        self.router = router
        self.dispatchQueue = dispatchQueue
        self.delegate = delegate
    }

    func start () {
        looper = DispatchWorkItem { [weak self] in
            self?.run()
        }
        dispatchQueue.async(execute: looper)
    }

    func run() {
        do {
            while !done.value {
                try processOne()
            }
            delegate.stopped(processor: self)
        } catch ConnectablePoolError.timeout {
            // currently just die, swift's concurrency cause this problem
            // TODO: add original awesome logic not to waste a resource
            delegate.died(processor: self, reason: ConnectablePoolError.timeout.localizedDescription)
        } catch {
            logger.error("\(error)")
            delegate.died(processor: self, reason: error.localizedDescription)
        }
    }

    func kill(_ wait: Bool = false) {
        done.value = true
        guard looper != nil, looper.isCancelled != true else { return }

        // cancel and waiting
        looper.cancel()
        delegate.stopped(processor: self)
        if wait {
            looper.wait()
        }
    }

    func terminate(_ wait: Bool = false) {
        done.value = true
        guard looper != nil, looper.isCancelled != true else { return }

        // just waiting
        if wait {
            looper.wait()
        }
    }

    func processOne() throws {
        if let work = try fetcher.retriveWork() {
            job = work
            defer { job = nil }
            if done.value {
                try work.requeue()
            } else {
                try process(work)
            }
        }
    }

    func process(_ work: UnitOfWork) throws {
        do {
            try router.dispatch(work, delegate: self)
        } catch RouterError.notFoundWorker {
            try didFailed(worker: work.workerType, work: work, error: RouterError.notFoundWorker)
        }
    }
    
    
    public func stats<W: Worker>(worker: W, work: UnitOfWork, block: () throws -> ()) throws {
        let tid = ThreadIdentityGenerator.makeIdentity()
        Processor.updateState(WorkerState(work: work, runAt: Date()), for: tid)
        defer {
            Processor.updateState(nil, for: tid)
            Processor.processedCounter.increment()
        }
        
        do {
            try block()
        } catch {
            Processor.failureCounter.increment()
            throw error
        }
    }
    
    public func didFailed<W : Worker>(worker: W, work: UnitOfWork, error: Error) throws {
        logger.error("ERROR: \(error) on \(worker)")
        let maxRetry = worker.retry ?? W.defaultRetry
        let currentDelay = work.retryCount ?? 0
        let nextDelay = Delay.next(for: worker, by: currentDelay)
        try attemptRetry(work: work, error: error, maxRetry: maxRetry, delay: nextDelay)
    }
    
    public func didFailed(worker: String, work: UnitOfWork, error: Error) throws {
        logger.error("ERROR: \(error) on \(worker)")
        let maxRetry = 25
        let currentDelay = work.retryCount ?? 0
        let nextDelay = Delay.next(by: currentDelay)
        try attemptRetry(work: work, error: error, maxRetry: maxRetry, delay: nextDelay)
    }

    func attemptRetry(work: UnitOfWork, error: Error, maxRetry: Int, delay: Int) throws {
        var newJob = work
        
        newJob.errorMessage = error.localizedDescription
        
        if let retryCount = newJob.retryCount {
            newJob.retriedAt = Date().timeIntervalSince1970
            newJob.retryCount = retryCount + 1
        } else {
            newJob.failedAt = Date().timeIntervalSince1970
            newJob.retryCount = 0
        }
        
        if let backtrace = newJob.backtrace {
            switch backtrace {
            case .on:
                newJob.errorBacktrace = Thread.callStackSymbols.joined()
            case .limited(let limit):
                let all = Thread.callStackSymbols.joined()
                newJob.errorBacktrace = all.substring(to: all.index(all.startIndex, offsetBy: String.IndexDistance(limit)))
            default:
                break
            }
        }
        
        let current = work.retryCount ?? 0
        if current < maxRetry {
            // TODO: logging
            let retryAt = Date().timeIntervalSince1970 + Double(delay)
            logger.debug("retry after \(delay) sec")
            _ = try connectionPool.with { conn in
                try conn.add(newJob, with: .value(retryAt), to: RetrySet())
            }
        } else {
            try retriesExthusted(work: work, error: error)
        }
        
        // do not throw error in heare
        // because this is only delegate
    }
    
    func retriesExthusted(work: UnitOfWork, error: Error) throws {
        logger.debug("retries exthusted for job")
        
        guard let dead = work.dead, dead != false else { return }
        
        let payload = try JSONEncoder().encode(work)
        let now = Date().timeIntervalSince1970
        let score = SortedSetScore.value(now)
        let deadSet = DeadSet()
        let minusInf = SortedSetScore.infinityNegative.string.makeBytes()
        let toDeleteScore = SortedSetScore.value(now - DeadSet.timeout).string.makeBytes()
        
        try connectionPool.with { conn in
            try conn.pipelined()
                .enqueue(Command("ZADD"), [deadSet.key, score.string.makeBytes(), payload.makeBytes()])
                .enqueue(Command("ZREMRANGEBYSCORE"), [deadSet.key, minusInf, toDeleteScore])
                .enqueue(Command("ZREMRANGEBYRANK"), [deadSet.key, "0".makeBytes(), "\(DeadSet.maxJobs)".makeBytes()])
                .execute()
        }
    }
}

extension Processor: CustomStringConvertible {
    public var description: String {
        return "<Processor label=\"\(dispatchQueue.label)\" job=\"\(String(describing: job))\")>"
    }
}

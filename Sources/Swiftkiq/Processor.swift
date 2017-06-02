//
//  Processor.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Dispatch

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

    let tid: Tid
    let dispatchQueue: DispatchQueue
    private var looper: DispatchWorkItem!

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
        self.tid = ThreadIdentityGenerator.makeIdentity(from: dispatchQueue)
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
        var newJob = work.job
        
        newJob["error_message"] = error.localizedDescription
        
        if let retryCount = newJob["retry_count"] as? Int {
            newJob["retried_at"] = Date().timeIntervalSince1970
            newJob["retry_count"] = retryCount + 1
        } else {
            newJob["failed_at"] = Date().timeIntervalSince1970
            newJob["retry_count"] = 0
        }
        
        let backtrace = newJob["backtrace"] ?? false
        switch backtrace {
        case is Bool:
            let backtraceBool = backtrace as! Bool
            if backtraceBool {
                newJob["error_backtrace"] = Thread.callStackSymbols
            }
        case is Int:
            let backtraceInt = backtrace as! Int
            let all = Thread.callStackSymbols.joined()
            newJob["error_backtrace"] = all.substring(to: all.index(all.startIndex, offsetBy: backtraceInt))
        default:
            break
        }
        
        let current = work.retryCount ?? 0
        if current < maxRetry {
            // TODO: logging
            let retryAt = Date().timeIntervalSince1970 + Double(delay)
            logger.debug("retry after \(delay) sec")
            _ = try Application.connectionPool { conn in
                try conn.add(newJob, with: .value(retryAt), to: RetrySet())
            }
        } else {
            // TODO: retries_exhausted
        }
        
        // do not throw error in heare
        // because this is only delegate
    }
}

extension Processor: CustomStringConvertible {
    public var description: String {
        return "<Processor label=\"\(dispatchQueue.label)\" job=\"\(String(describing: job))\")>"
    }
}

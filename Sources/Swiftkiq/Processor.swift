//
//  Processor.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Dispatch

public protocol WorkerFailureCallback {
    func didFailed<W : Worker>(worker: W, work: UnitOfWork, error: Error)
}

public final class Processor: WorkerFailureCallback {
    private static let mutex = Mutex()
    private static var _workerState = [Jid: WorkerState]()

    static var workerStates: [Jid: WorkerState] {
        return mutex.synchronize { return _workerState }
    }

    static func updateState(_ value: WorkerState?, for jid: Jid) {
        mutex.synchronize { _workerState[jid] = value }
    }

    static var processedCounter = AtomicCounter<Int>(0)
    static var failureCounter = AtomicCounter<Int>(0)

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
        try router.dispatch(work, errorCallback: self)
    }

    public func didFailed<W : Worker>(worker: W, work: UnitOfWork, error: Error) {
        logger.error("ERROR: \(error) on \(worker)")
        attemptRetry(worker: worker, work: work, error: error)
    }

    func attemptRetry<W: Worker>(worker: W, work: UnitOfWork, error: Error) {
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

        let max = worker.retry ?? W.defaultRetry
        let current = work.retryCount ?? 0
        if current < max {
            // TODO: logging
            let delay = Delay.next(for: worker, by: current)
            let retryAt = Date().timeIntervalSince1970 + Double(delay)
            logger.debug("retry after \(delay) sec")
            _ = try! SwiftkiqClient.connectionPool { conn in
                try! conn.add(newJob, with: .value(retryAt), to: RetrySet())
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

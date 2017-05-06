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

    let fetcher: Fetcher
    let router: Routable
    let dipsatchQueue: DispatchQueue
    weak var delegate: ProcessorLifecycleDelegate!

    var down: Bool = false
    var done: Bool = false

    init(fetcher: Fetcher,
         router: Routable,
         dispatchQueue: DispatchQueue,
         delegate: ProcessorLifecycleDelegate) {
        self.fetcher = fetcher
        self.router = router
        self.dipsatchQueue = dispatchQueue
        self.delegate = delegate
    }

    func start () {
        dipsatchQueue.async { self.run() }
    }

    func run() {
        while !done {
            do {
                try processOne()
            } catch Manager.Control.shutdown {
                break
            } catch {
                // handle error at didFailed
            }
        }
    }
    
    func terminate() {
        fatalError("not implemented yet")
    }

    func processOne() throws {
        if let work = try fetcher.retriveWork() {
            try process(work)
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
            try! SwiftkiqClient.current.store.add(newJob, with: .value(retryAt), to: RetrySet())
        } else {
            // TODO: retries_exhausted
        }

        // do not throw error in heare
        // because this is only delegate
    }
}

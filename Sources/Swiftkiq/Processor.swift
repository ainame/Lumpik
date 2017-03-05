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

    func processOne() throws {
        if let work = try fetcher.retriveWork() {
            try process(work)
        }
    }

    func process(_ work: UnitOfWork) throws {
        try router.dispatch(work, errorCallback: self)
    }

    public func didFailed<W : Worker>(worker: W, work: UnitOfWork, error: Error) {
        print("ERROR: \(error) on \(worker)")
        attemptRetry(worker: worker, work: work, error: error)
    }

    func attemptRetry<W: Worker>(worker: W, work: UnitOfWork, error: Error) {
        let max = worker.retry ?? W.defaultRetry
        let current = work.retryCount ?? 0

        if current < max {
            var newJob = work.job
            newJob["retryCount"] = current + 1
            let args = W.Args.from(newJob)
            try! SwiftkiqClient.current.enqueue(class: W.self, args: args, to: work.queue)
        }
    }
}

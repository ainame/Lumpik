//
//  Routable.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/02.
//
//

import Foundation
import SwiftyBeaver

public enum RouterError: Error {
    case notFoundWorker
}

public protocol Routable {
    func dispatch(_ work: UnitOfWork, errorCallback: WorkerFailureCallback) throws
    func invokeWorker<W: Worker>(workerType: W.Type, work: UnitOfWork, errorCallback: WorkerFailureCallback) throws
}

extension Routable {
    public func invokeWorker<W: Worker>(workerType: W.Type, work: UnitOfWork, errorCallback: WorkerFailureCallback) throws {
        var worker = workerType.init()
        let argument = workerType.Args.from(work.args)
        worker.jid = work.jid
        worker.retry = work.retry
        worker.queue = work.queue

        logger.info("jid=\(work.jid) \(work.workerType) start")
        let start = Date()
        defer {
            let interval = Date().timeIntervalSince(start)
            logger.info("jid=\(work.jid) \(work.workerType) done - \(interval) msec")
        }
        
        do {
            try stats(worker: worker, work: work) {
                try worker.perform(argument)
            }
        } catch let error {
            errorCallback.didFailed(worker: worker, work: work, error: error)
            throw error
        }
    }
    
    func stats<W: Worker>(worker: W, work: UnitOfWork, block: () throws -> ()) throws {
        Processor.updateState(WorkerState(work: work, runAt: Date()), for: work.jid)
        defer {
            Processor.updateState(nil, for: work.jid)
            Processor.processedCounter.increment()
        }
        
        do {
            try block()
        } catch {
            Processor.failureCounter.increment()
            throw error
        }
    }

}

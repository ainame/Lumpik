//
//  Routable.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/03/02.
//
//

import Foundation
import SwiftyBeaver

public enum RouterError: Error {
    case notFoundWorker
    case cantDeserializeArgument
}

public protocol Routable {
    func dispatch(_ work: UnitOfWork, delegate: RouterDelegate) throws
    func invokeWorker<W: Worker>(workerType: W.Type, work: UnitOfWork, delegate: RouterDelegate) throws
}

public protocol RouterDelegate {
    func stats<W: Worker>(worker: W, work: UnitOfWork, block: () throws -> ()) throws
    func didFailed<W : Worker>(worker: W, work: UnitOfWork, error: Error) throws
    func didFailed(worker: String, work: UnitOfWork, error: Error) throws
}

extension Routable {
    public func invokeWorker<W: Worker>(workerType: W.Type, work: UnitOfWork, delegate: RouterDelegate) throws {
        let args = try JsonConverter.default.deserialize(array: work.args.makeString())
        guard let argument = workerType.Args.from(args) else {
            throw RouterError.cantDeserializeArgument
        }
        
        var worker = workerType.init()
        worker.jid = work.jid
        worker.retry = work.retryLimit
        worker.queue = work.queue

        logger.info("jid=\(work.jid) \(work.workerType) start")
        let start = Date()
        defer {
            let interval = Date().timeIntervalSince(start)
            logger.info("jid=\(work.jid) \(work.workerType) done - \(interval) msec")
        }
        
        do {
            try delegate.stats(worker: worker, work: work) {
                try worker.perform(argument)
            }
        } catch let error {
            try delegate.didFailed(worker: worker, work: work, error: error)
            throw error
        }
    }
}

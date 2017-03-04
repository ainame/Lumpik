//
//  Routable.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/02.
//
//

import Foundation

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

        print(String(format: "[INFO]: jid=%@ %@ start", work.jid, work.workerType))
        let start = Date()
        defer {
            let interval = Date().timeIntervalSince(start)
            print(String(format: "[INFO]: jid=%@ %@ done - %.4f msec", work.jid, work.workerType, interval))
        }
        do {
            try worker.perform(argument)
        } catch let error {
            errorCallback.didFailed(workerType: workerType, error: error)
            throw error
        }
    }
}

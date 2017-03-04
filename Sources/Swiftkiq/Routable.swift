//
//  Routable.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/02.
//
//

import Foundation

public protocol Routable {
    func dispatch(_ work: UnitOfWork) throws
    func invokeWorker<W: Worker>(workerType: W.Type, work: UnitOfWork) throws
}

extension Routable {
    func invokeWorker<W: Worker>(workerType: W.Type, work: UnitOfWork) throws {
        var worker = workerType.init()
        let argument = workerType.Args.from(work.args)
        worker.jid = work.jid
        worker.retry = work.retry
        worker.queue = work.queue
        print(String(format: "[INFO]: jid=%@ %@ start", work.jid, work.workerType))
        let start = Date()
        try worker.perform(argument)
        let interval = Date().timeIntervalSince(start)
        print(String(format: "[INFO]: jid=%@ %@ done - %.4f msec", work.jid, work.workerType, interval))
    }
}

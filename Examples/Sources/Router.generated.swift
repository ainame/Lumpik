// Generated using Sourcery 0.5.8 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation
import Swiftkiq

class Router: Routable {
    func dispatch(processorId: Int, work: UnitOfWork) throws {
        switch work.workerClass {
        case "EchoWorker":
            try invokeWorker(processorId: processorId, workerClass: EchoWorker.self, work: work)
        default:
            break
        }
    }

    func invokeWorker<W: Worker>(processorId: Int, workerClass: W.Type, work: UnitOfWork) throws {
        let worker = workerClass.init()
        let argument = workerClass.Args.from(work.args)
        worker.processorId = processorId
        worker.jid = work.jid
        worker.retry = work.retry
        worker.queue = work.queue
        print(String(format: "[INFO]: jid=%@ %@ start", work.jid, work.workerClass))
        let start = Date()
        try worker.perform(argument)
        let interval = Date().timeIntervalSince(start)
        print(String(format: "[INFO]: jid=%@ %@ done - %.4f msec", work.jid, work.workerClass, interval))
    }
}

// Generated using Sourcery 0.5.8 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation
import Swiftkiq

class Router: Routable {
    func dispatch(_ work: UnitOfWork) throws {
        switch work.workerClass {
        case "EchoWorker":
            try invokeWorker(workerClass: EchoWorker.self, work: work)
        default:
            break
        }
    }

    func invokeWorker<Worker: WorkerType>(workerClass: Worker.Type, work: UnitOfWork) throws {
        let worker = workerClass.init()
        let argument = workerClass.Argument.from(work.argument)
        worker.jid = work.jid
        worker.retry = work.retry
        worker.queue = work.queue
        print("[INFO]: \(work.workerClass) start")
        let start = Date()
        try worker.perform(argument)
        let interval = Date().timeIntervalSince(start)
        print(String(format: "[INFO]: jid=%@ %@ done - %.4f msec", work.jid, work.workerClass, interval))
    }
}
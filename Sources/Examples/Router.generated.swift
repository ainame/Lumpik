// Generated using Sourcery 0.5.8 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


import Foundation
import Swiftkiq

class Router: Routable {
    func dispatch(_ work: UnitOfWork, errorCallback: WorkerFailureCallback) throws {
        switch work.workerType {
        case "ComplexWorker":
            try invokeWorker(workerType: ComplexWorker.self, work: work, errorCallback: errorCallback)
        case "EchoWorker":
            try invokeWorker(workerType: EchoWorker.self, work: work, errorCallback: errorCallback)
        default:
            break
        }
    }
}

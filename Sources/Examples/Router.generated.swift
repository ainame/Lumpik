// Generated using Sourcery 0.5.8 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


import Foundation
import Swiftkiq

class Router: Routable {
    func dispatch(_ work: UnitOfWork, errorCallback: WorkerFailureCallback) throws {
        switch work.workerType {
        case String(describing: ComplexWorker.self):
            try invokeWorker(workerType: ComplexWorker.self, work: work, errorCallback: errorCallback)
        case String(describing: EchoWorker.self):
            try invokeWorker(workerType: EchoWorker.self, work: work, errorCallback: errorCallback)
        default:
            throw RouterError.notFoundWorker
        }
    }
}

extension ComplexWorker.Args {
    func toArray() -> [Any] {
        return [
            userId,
            comment,
            data,
        ]
    }

    static func from(_ array: [Any]) -> ComplexWorker.Args {
        // NOTE: currently stencil template engine can not provide counter with starting 0
        return ComplexWorker.Args(
            userId: array[1 - 1] as! Int,
            comment: array[2 - 1] as! String,
            data: array[3 - 1] as! [String: Any]
        )
    }
}
extension EchoWorker.Args {
    func toArray() -> [Any] {
        return [
            message,
        ]
    }

    static func from(_ array: [Any]) -> EchoWorker.Args {
        // NOTE: currently stencil template engine can not provide counter with starting 0
        return EchoWorker.Args(
            message: array[1 - 1] as! String
        )
    }
}

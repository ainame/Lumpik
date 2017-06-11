// Generated using Sourcery 0.5.8 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


import Foundation
import Lumpik

class Router: Routable {
    func dispatch(_ work: UnitOfWork, delegate: RouterDelegate) throws {
        switch work.workerType {
        case String(describing: ComplexWorker.self):
            try invokeWorker(workerType: ComplexWorker.self, work: work, delegate: delegate)
        case String(describing: EchoWorker.self):
            try invokeWorker(workerType: EchoWorker.self, work: work, delegate: delegate)
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

    static func from(_ array: [Any]) -> ComplexWorker.Args? {
        guard let userId = array[1 - 1] as? Int,
            let comment = array[2 - 1] as? String,
            let data = array[3 - 1] as? [String: Any] else {
            return nil
        }

        // NOTE: currently stencil template engine can not provide counter with starting 0
        return ComplexWorker.Args(
            userId: userId,
            comment: comment,
            data: data
        )
    }
}

extension EchoWorker.Args {
    func toArray() -> [Any] {
        return [
            message,
        ]
    }

    static func from(_ array: [Any]) -> EchoWorker.Args? {
        guard let message = array[1 - 1] as? String else {
            return nil
        }

        // NOTE: currently stencil template engine can not provide counter with starting 0
        return EchoWorker.Args(
            message: message
        )
    }
}

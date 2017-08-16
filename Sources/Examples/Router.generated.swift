// Generated using Sourcery 0.7.2 — https://github.com/krzysztofzablocki/Sourcery
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
    func toArray() -> [AnyArgumentValue] {
        return [
            userId,
            comment,
        ].map { AnyArgumentValue($0) }
    }

    static func from(_ array: [AnyArgumentValue]) -> ComplexWorker.Args? {
        // NOTE: currently stencil template engine can not provide counter with starting 0
        let userId = array[1 - 1].intValue
        let comment = array[2 - 1].stringValue

        return ComplexWorker.Args(
            userId: userId,
            comment: comment
        )
    }
}

extension EchoWorker.Args {
    func toArray() -> [AnyArgumentValue] {
        return [
            message,
        ].map { AnyArgumentValue($0) }
    }

    static func from(_ array: [AnyArgumentValue]) -> EchoWorker.Args? {
        // NOTE: currently stencil template engine can not provide counter with starting 0
        let message = array[1 - 1].stringValue

        return EchoWorker.Args(
            message: message
        )
    }
}

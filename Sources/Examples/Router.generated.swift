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
    func toArray() -> [AnyArgumentValue] {
        return [
            userId,
            comment,
        ].map { AnyArgumentValue($0) }
    }

    static func from(_ array: [AnyArgumentValue]) -> ComplexWorker.Args? {
        // NOTE: currently stencil template engine can not provide counter with starting 0
        guard let userId = Int(array[1 - 1].description) ,
            let comment = String(array[2 - 1].description)  else {
            return nil
        }

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
        guard let message = String(array[1 - 1].description)  else {
            return nil
        }

        return EchoWorker.Args(
            message: message
        )
    }
}

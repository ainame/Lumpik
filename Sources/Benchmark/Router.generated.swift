// Generated using Sourcery 0.5.8 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


import Foundation
import Lumpik

class Router: Routable {
    func dispatch(_ work: UnitOfWork, delegate: RouterDelegate) throws {
        switch work.workerType {
        case String(describing: EchoWorker.self):
            try invokeWorker(workerType: EchoWorker.self, work: work, delegate: delegate)
        default:
            throw RouterError.notFoundWorker
        }
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

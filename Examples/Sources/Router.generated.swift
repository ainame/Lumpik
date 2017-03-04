// Generated using Sourcery 0.5.8 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation
import Swiftkiq

class Router: Routable {
    func dispatch(_ work: UnitOfWork) throws {
        switch work.workerType {
        case "EchoWorker":
            try invokeWorker(workerType: EchoWorker.self, work: work)
        default:
            break
        }
    }
}

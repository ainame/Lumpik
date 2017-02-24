import XCTest
@testable import Swiftkiq

class SwiftkiqTests: XCTestCase {
    enum MainQueue: String, Queue {
        var string: String {
            return rawValue
        }

        case `default`, light, heavy
    }

    public class MemoryStore: ListStorable {
        var all = Dictionary<String, Array<Job>>()

        public func enqueue(_ job: Job, to queue: Queue) {
            if var list = all[queue.string] {
                list.append(job)
            } else {
                var list = Array<Job>()
                list.append(job)
                all[queue.string] = list
            }
        }

        public func dequeue(_ queue: Queue) -> Job? {
            return all[queue.string]?.removeFirst()
        }
    }

    struct EchoMessageWorkerJob: Job {
        var message: String

        func serialized() -> [String : Any] {
            return [
                "message": message
            ]
        }
    }

    final class EchoMessageWorker: Worker {
        typealias Argument = EchoMessageWorkerJob

        static let queue = MainQueue.default
        static let retry = 1

        init() {
        }
        
        func perform(_ job: EchoMessageWorkerJob) {
            print(job.message)
        }
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let job = EchoMessageWorkerJob(message: "Hello, World!")
        EchoMessageWorker.performAsync(job)
    }


    static var allTests : [(String, (SwiftkiqTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}

import XCTest
@testable import Swiftkiq

class SwiftkiqTests: XCTestCase {
    final class EchoMessageWorker: Worker {
        struct Argument: ArgumentType {
            let message: String
        }

        static let queue = Queue("default")
        static let retry = 1

        func perform(_ job: Argument) {
            print(job.message)
        }
    }
    
    func testExample() {
        try! EchoMessageWorker.performAsync(.init(message: "Hello, World!"))
        XCTAssertNotNil(EchoMessageWorker.client.store.dequeue(Queue("default")))
    }


    static var allTests : [(String, (SwiftkiqTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}

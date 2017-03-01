import XCTest
@testable import Swiftkiq

class SwiftkiqTests: XCTestCase {
    struct EchoMessageJob: Job {
        let jid: String
        let `class` = EchoMessageWorker.self
        let argument: EchoMessageWorker.Argument
        let retry: Int
        let queue: Queue
    }
    
    final class EchoMessageWorker: Worker {
        struct Argument: ArgumentType {
            let message: String
        }

        static let queue = Queue("default")
        static let retry = 1
        var jid: String?

        func perform(_ job: Argument) {
            print(job.message)
        }
    }
    
    func testExample() {
        try! EchoMessageWorker.performAsync(.init(message: "Hello, World!"))
        XCTAssertNotNil(try! EchoMessageWorker.client.store.dequeue(Queue("default")))
    }
    
    func testRedis() {
        try! Swiftkiq.store.enqueue(["hoge": 1], to: Queue("default"))
        do {
            let work = try Swiftkiq.store.dequeue(Queue("default"))
            XCTAssertNotNil(work)
        } catch(let error) {
            print(error)
            XCTFail()
        }
    }
    
    func testRedisEmptyDequeue() {
        do {
            let work = try Swiftkiq.store.dequeue(Queue("default"))
            XCTAssertNil(work)
        } catch(let error) {
            print(error)
            XCTFail()
        }
    }


    static var allTests : [(String, (SwiftkiqTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}

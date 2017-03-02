import XCTest
@testable import Swiftkiq

class SwiftkiqTests: XCTestCase {
    struct EchoMessageJob: JobType {
        static let `class` = EchoMessageWorker.self
        let jid: String
        let argument: EchoMessageWorker.Argument
        let retry: Int
        let queue: Queue
    }
    
    final class EchoMessageWorker: WorkerType {
        struct Argument: ArgumentType {
            let message: String
            
            static func from(_ dictionary: Dictionary<String, Any>) -> Argument {
                return Argument(
                    message: dictionary["message"]! as! String
                )
            }
        }

        var jid: String?
        var queue: Queue?
        var retry: Int?

        func perform(_ job: Argument) {
            print(job.message)
        }
    }
    
    func testExample() {
        try! EchoMessageWorker.performAsync(.init(message: "Hello, World!"))
        XCTAssertNotNil(try! Swiftkiq.store.dequeue([Queue("default")]))
    }
    
    func testRedis() {
        try! Swiftkiq.store.enqueue(["hoge": 1], to: Queue("default"))
        do {
            let work = try Swiftkiq.store.dequeue([Queue("default")])
            XCTAssertNotNil(work)
        } catch(let error) {
            print(error)
            XCTFail()
        }
    }
    
    func testRedisEmptyDequeue() {
        do {
            let work = try Swiftkiq.store.dequeue([Queue("default")])
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

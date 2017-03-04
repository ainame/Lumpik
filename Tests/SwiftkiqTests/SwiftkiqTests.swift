import XCTest
@testable import Swiftkiq

// need redis-server for host: '127.0.0.1', port: 6379
class SwiftkiqTests: XCTestCase {

    override func setUp() {
        try! Queue("default").clear()
    }
    
    final class EchoMessageWorker: Worker {
        struct Args: Argument {
            let message: String
            
            func toDictionary() -> [String : Any] {
                return [
                    "message": message
                ]
            }

            static func from(_ dictionary: Dictionary<String, Any>) -> Args {
                return Args(
                    message: dictionary["message"]! as! String
                )
            }
        }

        var jid: String?
        var queue: Queue?
        var retry: Int?

        func perform(_ job: Args) {
            print(job.message)
        }
    }
    
    func testExample() {
        try! EchoMessageWorker.performAsync(.init(message: "Hello, World!"))
        XCTAssertNotNil(try! SwiftkiqCore.store.dequeue([Queue("default")]))
    }
    
    func testRedis() {
        try! SwiftkiqCore.store.enqueue(["hoge": 1, "queue": "default"], to: Queue("default"))
        do {
            let work = try SwiftkiqCore.store.dequeue([Queue("default")])
            XCTAssertNotNil(work)
        } catch(let error) {
            print(error)
            XCTFail()
        }
    }
    
    func testRedisEmptyDequeue() {
        do {
            let work = try SwiftkiqCore.store.dequeue([Queue("default")])
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

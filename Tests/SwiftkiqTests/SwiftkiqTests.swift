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

        func perform(_ args: Args) {
            print(args.message)
        }
    }
    
    func testExample() {
        try! EchoMessageWorker.performAsync(.init(message: "Hello, World!"))
        XCTAssertNotNil(try! SwiftkiqClient.current.store.dequeue([Queue("default")]))
    }
    
    func testFetcher() {
        let fetcher = BasicFetcher(queues: [Queue("1"), Queue("2"), Queue("3")])
        print(fetcher.randomSortedQueues())
        XCTAssertNotNil(fetcher.randomSortedQueues())
    }
    
    func testRedis() {
        try! SwiftkiqClient.current.store.enqueue(["hoge": 1, "queue": "default"], to: Queue("default"))
        do {
            let work = try SwiftkiqClient.current.store.dequeue([Queue("default")])
            XCTAssertNotNil(work)
        } catch(let error) {
            print(error)
            XCTFail()
        }
    }
    
    func testRedisEmptyDequeue() {
        do {
            let work = try SwiftkiqClient.current.store.dequeue([Queue("default")])
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

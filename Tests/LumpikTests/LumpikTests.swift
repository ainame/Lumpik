import XCTest
import Foundation
import Redis
@testable import Lumpik

// need redis-server for host: '127.0.0.1', port: 6379
class LumpikTests: XCTestCase {
    static var allTests : [(String, (LumpikTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
            ("testFetcher", testFetcher),
            ("testRedis", testRedis),
            ("testRedisEmptyDequeue", testRedisEmptyDequeue),
            ("testTransaction", testTransaction),
        ]
    }


    final class EchoMessageWorker: Worker {
        struct Args: Argument {
            let message: String
            
            func toArray() -> [Any] {
                return [message]
            }
            
            static func from(_ array: [Any]) -> Args {
                return Args(
                    message: array[0] as! String
                )
            }
        }
        
        var jid: Jid?
        var queue: Queue?
        var retry: Int?
        
        static var defaultQueue = Queue("test")
        
        func perform(_ args: Args) {
            print(args.message)
        }
    }

    let pool = SingleConnectionPool()

    override func setUp() {
        LumpikClient.connectionPool = AnyConnectablePool(pool)
        // try! Queue("test").clear()
    }

    func testExample() throws {
        try EchoMessageWorker.performAsync(.init(message: "Hello, World!"))
        _ = try pool.with { conn in
            let result = try conn.dequeue([Queue("test")])
            XCTAssertNotNil(result)
        }
    }

    func testFetcher() {
        let fetcher = BasicFetcher(queues: [Queue("1"), Queue("2"), Queue("3")])
        print(fetcher.randomSortedQueues())
        XCTAssertNotNil(fetcher.randomSortedQueues())
    }

    func testRedis() throws {
        _ = try pool.with { conn in
            try conn.enqueue(["hoge": 1, "queue": "default"], to: Queue("default"))
            do {
                _ = try conn.dequeue([Queue("default")])
                XCTFail()
            } catch {
                XCTAssertNotNil(error)
            }
        }
    }

    func testRedisEmptyDequeue() throws {
        _ = try pool.with { conn in
            do {
                let work = try conn.dequeue([Queue("default")])
                XCTAssertNil(work)
            } catch(let error) {
                print(error)
                XCTFail()
            }
        }
    }

    func testTransaction() throws {
        _ = try pool.with { conn in
            do {
                // will success
                let responses = try conn.pipelined()
                    .enqueue(Command("MULTI"))
                    .enqueue(Command("SET"), ["default", "1"])
                    .enqueue(Command("INCR"), ["default"])
                    .enqueue(Command("INCR"), ["default"])
                    .enqueue(Command("EXEC"))
                    .execute()
                
                let verified = RedisStore.verify(pipelinedResponses: responses)
                XCTAssertTrue(verified.errors.isEmpty)
            }

            do {
                let responses = try conn.pipelined()
                    .enqueue(Command("MULTI"))
                    .enqueue(Command("SET"), ["default", "1", "2"])
                    .enqueue(Command("INCR"), ["default", "absc"]) // will fail
                    .enqueue(Command("EXEC"))
                    .execute()
                
                let verified = RedisStore.verify(pipelinedResponses: responses)
                XCTAssertFalse(verified.errors.isEmpty)
            }
        }
    }
}

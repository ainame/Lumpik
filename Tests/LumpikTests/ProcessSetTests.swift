//
//  ProcessTests.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/03/07.
//
//

import XCTest
import Foundation
import Dispatch
@testable import Lumpik

// do not use with other thread
final class SingleConnectionPool: ConnectablePool {
    var redis: RedisStore
    
    init() {
        redis = try! RedisStore(host: "localhost", port: 6379)
    }

    func borrow() throws -> RedisStore {
        return redis
    }
    func checkin(_ connection: RedisStore) {
        //
    }
}

class ProcessSetTests: XCTestCase {
    static var allTests : [(String, (ProcessSetTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let pool = SingleConnectionPool()
        ProcessSet.connectionPool = AnyConnectablePool<RedisStore>(pool)
        Heart.connectionPoolForInternal = AnyConnectablePool<RedisStore>(pool)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() throws {
        let string = "{ \"hostname\": \"app-1.example.com\", \"started_at\": 12345678910, \"pid\": 12345, \"tag\": \"myapp\", \"concurrency\": 25, \"labels\": [], \"queues\": [\"default\", \"low\"],\"busy\": 10,\"beat\": 12345678910,\"identity\": \"<unique string identifying the process>\"}"
        let data = string.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
        let dict = json as! NSDictionary
        let process = Lumpik.Process.from(dict)
        XCTAssertNotNil(process)
                
        let heart = Heart(concurrency: 25, queues: [Queue("default")])
        try heart.beat(done: false)
        try ProcessSet().each { process in
            print(process)
            XCTAssertNotNil(process)
        }
    }
}

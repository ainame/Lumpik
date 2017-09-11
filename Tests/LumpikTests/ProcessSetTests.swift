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
        let string = "{ \"hostname\": \"app-1.example.com\", \"started_at\": 12345678910, \"pid\": 12345, \"tag\": \"myapp\", \"concurrency\": 25, \"labels\": [], \"queues\": [\"default\", \"low\"],\"busy\": 10,\"beat\": 12345678910,\"identity\": \"<unique string i dentifying the process>\"}"
        let data = string.data(using: .utf8)!
        let process = try JSONDecoder().decode(Lumpik.Process.self, from:data)
        XCTAssertNotNil(process)
                
        let heart = Heart(concurrency: 25, queues: [Queue("default")])
        try heart.beat(done: false)
        XCTAssertNoThrow(
            try ProcessSet().each { process in
                print(process)
                XCTAssertNotNil(process)
            }
        )
    }
}

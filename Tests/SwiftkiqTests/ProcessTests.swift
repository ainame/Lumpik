//
//  ProcessTests.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/07.
//
//

import XCTest
@testable import Swiftkiq

class ProcessTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() throws {
        let string = "{ \"hostname\": \"app-1.example.com\", \"started_at\": 12345678910, \"pid\": 12345, \"tag\": \"myapp\", \"concurrency\": 25,\"queues\": [\"default\", \"low\"],\"busy\": 10,\"beat\": 12345678910,\"identity\": \"<unique string identifying the process>\"}"
        let data = string.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
        let dict = json as! NSDictionary
        let process = Swiftkiq.Process.from(dict)
        XCTAssertNotNil(process)
    }
}

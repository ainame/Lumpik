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
    
    func testIndentity() throws {
        let nonce = ProcessIdentityGenerator.processNonce
        print(nonce)
        XCTAssertGreaterThanOrEqual(nonce.characters.count, 6)
        
        let jid = JobIdentityGenerator.identity()
        XCTAssertGreaterThanOrEqual(jid.rawValue.characters.count, 12)
        
        let tid1 = ThreadIdentityGenerator.identity(from: DispatchQueue(label: "aa"))
        let tid2 = ThreadIdentityGenerator.identity(from: DispatchQueue(label: "aa"))
        let tid3 = ThreadIdentityGenerator.identity(from: DispatchQueue(label: "bb"))
        XCTAssertEqual(tid1, tid2)
        XCTAssertNotEqual(tid1, tid3)
    }
}

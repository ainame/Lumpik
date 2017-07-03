//
//  WorkerTests.swift
//  Examples
//
//  Created by Satoshi Namai on 2017/07/04.
//

import XCTest
@testable import Lumpik

class AnyArgumentValueTests: XCTestCase {
    static var allTests : [(String, (AnyArgumentValueTests) -> () throws -> Void)] {
        return [
            ("testCorcionToString", testCorecionToString),
            ("testCorecionToInt", testCorecionToInt),
        ]
    }
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    func testCorecionToString() throws {
        let val1 = [AnyArgumentValue("string")]
        let encoded = try encoder.encode(val1)
        let decoded = try decoder.decode([AnyArgumentValue].self, from: encoded)
        XCTAssertTrue(decoded.map { String($0.description) } == val1.map { String($0.description) })
    }
    
    func testCorecionToInt() throws {
        let val1 = [AnyArgumentValue(1234)]
        let encoded = try encoder.encode(val1)
        let decoded = try decoder.decode([AnyArgumentValue].self, from: encoded)
        
        let actual = decoded.map { Int($0.description)! }
        let expected = val1.map { Int($0.description)! }
        XCTAssertTrue(actual == expected)
    }
    
    func testCorecionToDouble() throws {
        let val1 = [AnyArgumentValue(1234.5678)]
        let encoded = try encoder.encode(val1)
        let decoded = try decoder.decode([AnyArgumentValue].self, from: encoded)
        
        let actual = decoded.map { Double($0.description)! }
        let expected = val1.map { Double($0.description)! }
        XCTAssertTrue(actual == expected)
    }
}


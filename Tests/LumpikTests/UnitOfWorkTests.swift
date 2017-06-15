//
//  UnitOfWorkTests.swift
//  LumpikTests
//
//  Created by Namai Satoshi on 2017/06/09.
//

import XCTest
@testable import Lumpik

class UnitOfWorkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    struct TestToggleOrLimit: Codable {
        var on: UnitOfWork.ToggleOrLimit
        var off: UnitOfWork.ToggleOrLimit
        var limit: UnitOfWork.ToggleOrLimit
    }
    
    func testToggleOrLimitCodable() throws {
        let on = UnitOfWork.ToggleOrLimit.on
        let off = UnitOfWork.ToggleOrLimit.off
        let limit = UnitOfWork.ToggleOrLimit.limited(5)
        
        let instance = TestToggleOrLimit(on: on, off: off, limit: limit)
        let data = try JSONEncoder().encode(instance)
        XCTAssertNotNil(data)
        
        let restored = try JSONDecoder().decode(TestToggleOrLimit.self, from: data)
        XCTAssertNotNil(restored)
        
        if case .on = restored.on {
            XCTAssertTrue(true)
        } else {
            XCTFail()
        }
        
        if case .off = restored.off {
            XCTAssertTrue(true)
        } else {
            XCTFail()
        }
        
        if case .limited(5) = restored.limit {
            XCTAssertTrue(true)
        } else {
            XCTFail()
        }
    }
}

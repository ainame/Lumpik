//
//  Queue.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Mapper
import Bits

public protocol StoreKeyConvertible: RawRepresentable, Equatable, Hashable {
    var key: Bytes { get }
}

public class Queue: StoreKeyConvertible, CustomStringConvertible {
    public let rawValue: String

    public convenience init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
    
    public required init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var key: Bytes {
        return "queue:\(rawValue)".makeBytes()
    }
    
    public var description: String {
        return rawValue
    }
}

public class SortedSet: StoreKeyConvertible {
    public let rawValue: String
    
    public convenience init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
    
    public required init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var key: Bytes {
        return rawValue.makeBytes()
    }
}

public class Set: StoreKeyConvertible {
    public let rawValue: String
    
    public convenience init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
    
    public required init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var key: Bytes {
        return rawValue.makeBytes()
    }
}

extension SortedSet {
    public func count() throws -> Int {
        return try Application.connectionPool { try $0.size(self) }
    }
}

extension Set {
    public func count() throws -> Int {
        return try Application.connectionPool { try $0.size(self) }
    }
}

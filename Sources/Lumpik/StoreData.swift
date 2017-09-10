//
//  Queue.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Bits

public protocol StoreKeyConvertible: RawRepresentable, Hashable {
    var key: String { get }
}

extension StoreKeyConvertible {
    var connectionPoolForInternal: AnyConnectablePool<RedisStore> {
        return AnyConnectablePool(Application.default.connectionPoolForInternal)
    }
    
    public func clear() throws {
        _ = try connectionPoolForInternal.with { conn in
            try conn.clear(self)
        }
    }
    
    public func 💣() throws {
        try clear()
    }
}

public class Queue: StoreKeyConvertible, CustomStringConvertible, Codable {
    public let rawValue: String

    public convenience init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
    
    public required init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var key: String {
        return "queue:\(rawValue)"
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
    
    public var key: String {
        return rawValue
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
    
    public var key: String {
        return rawValue
    }
}

extension Queue {
    public func count() throws -> Int {
        return try connectionPoolForInternal.with { try $0.size(self) }
    }
}

extension SortedSet {
    public func count() throws -> Int {
        return try connectionPoolForInternal.with { try $0.size(self) }
    }
}

extension Set {
    public func count() throws -> Int {
        return try connectionPoolForInternal.with { try $0.size(self) }
    }
}

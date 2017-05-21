//
//  Queue.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Mapper

public protocol StoreKeyConvertible: RawRepresentable, Equatable, Hashable {
    var key: String { get }
}

public class Queue: StoreKeyConvertible {
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

extension SortedSet {
    public var size: Int {
        return try! Application.connectionPool { try! $0.size(self) }
    }
}

extension Set {
    public var size: Int {
        return try! Application.connectionPool { try! $0.size(self) }
    }
}

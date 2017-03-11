//
//  Store.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Mapper

public protocol Storable: ValueStorable, ListStorable, SetStorable, SortedSetStorable {
    static func makeStore() -> Storable
    func clear<K: StoreKeyConvertible>(_ queue: K) throws
}

public protocol ValueStorable {
    func get<K: StoreKeyConvertible>(_ key: K) throws -> String
    func set<K: StoreKeyConvertible>(_ key: K, value: String) throws
    func increment<K: StoreKeyConvertible>(_ key: K, by count: Int) throws -> Int
}

public protocol ListStorable {
    func enqueue(_ job: Dictionary<String, Any>, to queue: Queue) throws
    func dequeue(_ queues: [Queue]) throws -> UnitOfWork?
}

public protocol SetStorable {
    func add(_ job: Dictionary<String, Any>, to set: Set) throws
    func members<T: Mappable>(_ set: Set) throws -> [T]
    func size(_ set: Set) throws -> Int
}

public protocol SortedSetStorable {
    func add(_ job: Dictionary<String, Any>, with score: Int, to sortedSet: SortedSet) throws
    func size(_ sortedSet: SortedSet) throws -> Int
}

extension StoreKeyConvertible where Self: RawRepresentable, Self.RawValue == String {
    public var name: String {
        return rawValue
    }
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
}

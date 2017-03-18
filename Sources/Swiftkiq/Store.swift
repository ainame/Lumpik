//
//  Store.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Mapper

public protocol Storable: Transactionable, ValueStorable, ListStorable, SetStorable, SortedSetStorable {
    static func makeStore() -> Storable
    @discardableResult func clear<K: StoreKeyConvertible>(_ key: K) throws -> Int
}

public protocol ValueStorable {
    func get<K: StoreKeyConvertible>(_ key: K) throws -> String?
    @discardableResult func set<K: StoreKeyConvertible>(_ key: K, value: String) throws -> Bool
    @discardableResult func increment<K: StoreKeyConvertible>(_ key: K, by count: Int) throws -> Int
}

public protocol ListStorable {
    @discardableResult func enqueue(_ job: Dictionary<String, Any>, to queue: Queue) throws -> Int
    func dequeue(_ queues: [Queue]) throws -> UnitOfWork?
}

public protocol SetStorable {
    @discardableResult func add(_ job: Dictionary<String, Any>, to set: Set) throws -> Int
    func members<T: JsonConvertible>(_ set: Set) throws -> [T]
    func size(_ set: Set) throws -> Int
}

public protocol SortedSetStorable {
    @discardableResult func add(_ job: Dictionary<String, Any>, with score: Int, to sortedSet: SortedSet) throws -> Int
    func size(_ sortedSet: SortedSet) throws -> Int
}

public protocol Transaction {
    @discardableResult func addCommand(_ name: String, params: [String]) throws -> Self
    @discardableResult func exec() throws -> Bool
}

public protocol Transactionable {
    func multi() throws -> Transaction
}

extension StoreKeyConvertible where Self: RawRepresentable, Self.RawValue == String {
    public var name: String {
        return rawValue
    }
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
}

//
//  Store.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation

public protocol StoreKey: RawRepresentable, Equatable, Hashable {
    var key: String { get }
}

public protocol Storable: ListStorable, SortedSetStorable {
    static func makeStore() -> Storable
    func clear<K: StoreKey>(_ queue: K) throws
}

public protocol ListStorable {
    func enqueue(_ job: Dictionary<String, Any>, to queue: Queue) throws
    func dequeue(_ queues: [Queue]) throws -> UnitOfWork?
}

public protocol SortedSetStorable {
    func add(_ job: Dictionary<String, Any>, with score: Int, to sortedSet: SortedSet) throws
}

extension StoreKey where Self: RawRepresentable, Self.RawValue == String {
    public var name: String {
        return rawValue
    }
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
}

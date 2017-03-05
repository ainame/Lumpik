//
//  Queue.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation

public struct Queue: StoreKey {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var key: String {
        return "queue:\(rawValue)"
    }
    
    public func clear() throws {
        try SwiftkiqClient.current.store.clear(self)
    }
}

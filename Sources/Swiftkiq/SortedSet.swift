//
//  Set.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/05.
//
//

import Foundation

public struct SortedSet: StoreKey {
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var key: String {
        return rawValue
    }
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
}

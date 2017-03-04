//
//  Queue.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation

public struct Queue: RawRepresentable, Equatable, Hashable {
    public let rawValue: String

    var key: String {
        return "queue:\(rawValue)"
    }

    var name: String {
        return rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var hashValue: Int {
        return rawValue.hashValue
    }

    public func clear() throws {
        try SwiftkiqCore.makeStore().clear(self)
    }
}

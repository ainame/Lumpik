//
//  Identity.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/03/18.
//
//

import Foundation
import Dispatch

public protocol Identity: RawRepresentable, Equatable, Hashable, Comparable, CustomStringConvertible {}

extension Identity where RawValue == String {
    public var hashValue: Int {
        return self.rawValue.hashValue
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public static func <(lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var description: String {
        return rawValue
    }
}

// avoid duplicate name
public struct ProcessIdentity: Identity {
    public let rawValue: String
    
    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init?(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct Tid: Identity {
    public let rawValue: String
    
    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init?(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct Jid: Identity {
    public let rawValue: String
    
    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init?(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

struct ProcessIdentityGenerator {
    static let identity = ProcessIdentityGenerator.makeIdentity()
    
    // TODO: use SecureRandom.hex(6)
    static let processNonce = String(format: "%6x", UInt64(Compat.random(99_999_999)) * UInt64(Compat.random(10000)))
    static func makeIdentity() -> ProcessIdentity {
        let info = ProcessInfo.processInfo
        return ProcessIdentity("\(info.hostName)\(info.processIdentifier)\(processNonce)")!
    }
}

struct ThreadIdentityGenerator {
    static func makeIdentity() -> Tid {
        return Tid(String(Thread.current.hashValue, radix: 36))!
    }
}

struct JobIdentityGenerator {
    // TODO: use SecureRandom.hex(12)
    static func makeIdentity() -> Jid {
        let jid = String(format: "%x", UInt64(Compat.random(99_999_999)) * UInt64(Compat.random(99_999_999)))
        return Jid(jid)!
    }
}


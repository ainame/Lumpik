//
//  Identity.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/18.
//
//

import Foundation

public protocol Identity: RawRepresentable, Equatable, Hashable, Comparable, CustomStringConvertible {
}

public func < <I: Identity>(lhs: I, rhs: I) -> Bool where I.RawValue == String {
    return lhs.rawValue < rhs.rawValue
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
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
    
    public var description: String {
        return rawValue
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
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
    
    public var description: String {
        return rawValue
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
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
    
    public var description: String {
        return rawValue
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
    static func identity(from queue: DispatchQueue) -> Tid {
        let tid = "\(ProcessIdentityGenerator.identity)\(queue.label)".data(using: .utf8)!.base64EncodedString()
        return Tid(tid)!
    }
}

struct JobIdentityGenerator {
    // TODO: use SecureRandom.hex(12)
    static func identity() -> Jid {
        let jid = String(format: "%12x", UInt64(Compat.random(99_999_999)) * UInt64(Compat.random(10000)))
        return Jid(jid)!
    }
}


//
//  Worker.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation

public protocol Worker {
    associatedtype Args: Argument

    static var defaultQueue: Queue { get }
    static var defaultRetry: Int { get }
    static var retryIn: Int? { get }

    var jid: Jid? { get set }
    var queue: Queue? { get set }
    var retry: Int? { get set }

    init()
    static func performAsync(_ args: Args, on queue: Queue) throws
    func perform(_ args: Args) throws -> ()
}

public protocol Argument: Codable {
    func toArray() -> [AnyArgumentValue]
    static func from(_ array: [AnyArgumentValue]) -> Self?
}

public struct AnyArgumentValue: Codable, CustomStringConvertible {
    private let representedString: String
    
    public init<T>(_ value: T) {
        representedString = String(describing: value)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        representedString = try container.decode(String.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(representedString)
    }
    
    public var description: String {
        return representedString
    }
    
    public var intValue: Int {
        return Int(self.description)!
    }
    
    public var doubleValue: Double {
        return Double(self.description)!
    }
    
    public var stringValue: String {
        return String(self.description)
    }
}

extension Worker {
    public static var defaultQueue: Queue {
        return Queue("default")
    }

    public static var defaultRetry: Int {
        return 25
    }
    
    public static var retryIn: Int? {
        return nil
    }

    public static func performAsync(_ args: Args, on queue: Queue = Self.defaultQueue) throws {
        try LumpikClient.enqueue(class: self, args: args, to: queue)
    }
    
    public static func performIn(_ date: Date, _ args: Args, on queue: Queue = Self.defaultQueue) throws {
        let interval = date.timeIntervalSince1970
        try performIn(interval, args, on: queue)
    }
    
    public static func performIn(_ interval: TimeInterval, _ args: Args, on queue: Queue = Self.defaultQueue) throws {
        let now = Date().timeIntervalSince1970
        let realInterval = interval < 1000000000 ? now + interval : interval
        
        if realInterval <= now {
            // optimization
            try LumpikClient.enqueue(class: self, args: args, to: queue)
        } else {
            try LumpikClient.enqueue(class: self, args: args, to: queue, at: realInterval)
        }
        
    }
}

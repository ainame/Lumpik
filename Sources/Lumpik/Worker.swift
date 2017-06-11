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
}

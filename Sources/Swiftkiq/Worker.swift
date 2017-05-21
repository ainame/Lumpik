//
//  Worker.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation

public protocol Argument {
    func toArray() -> [Any]
    static func from(_ array: [Any]) -> Self
}

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
        try SwiftkiqClient.enqueue(class: self, args: args, to: queue)
    }
}

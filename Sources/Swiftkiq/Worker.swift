//
//  Worker.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation

public protocol Argument {
    static func from(_ dictionary: Dictionary<String, Any>) -> Self
}

public protocol Worker: class {
    associatedtype Args: Argument
    
    static var client: Client { get }
    static var defaultQueue: Queue { get }
    static var defaultRetry: Int { get }
    
    var jid: String? { get set }
    var queue: Queue? { get set }
    var retry: Int? { get set }


    init()
    static func performAsync(_ args: Args, to queue: Queue) throws
    func perform(_ args: Args) throws -> ()
}


extension Worker {
    public static var client: Client {
        return SwiftkiqClient.default
    }
    
    public static var defaultQueue: Queue {
        return Queue("default")
    }
    
    public static var defaultRetry: Int {
        return 25
    }
    
    public static func performAsync(_ args: Args, to queue: Queue = Self.defaultQueue) throws {
        try Self.client.enqueue(class: self, args: args, to: queue)
    }
}

//
//  Worker.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation

public protocol ArgumentType {
}

public protocol Worker {
    associatedtype Argument: ArgumentType
    
    static var client: Client { get }
    static var queue: Queue { get }
    static var retry: Int { get }
    
    static func performAsync(_ argument: Argument, to queue: Queue) throws
    func perform(_ argument: Argument) throws -> ()
}


extension Worker {
    public static var client: Client {
        return SwiftkiqClient.default
    }
    
    public static var queue: Queue {
        return Queue("default")
    }
    
    public static var retry: Int {
        return 25
    }
    
    public static func performAsync(_ argument: Argument, to queue: Queue = Self.queue) throws {
        try Self.client.enqueue(class: self, argument: argument, to: queue)
    }
}

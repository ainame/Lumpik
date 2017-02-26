//
//  Client.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation

public protocol Client {
    var store: ListStorable { get }
    func enqueue<W: Worker, Argument: ArgumentType>(`class`: W.Type, argument: Argument, to queue: Queue) throws
}

public struct SwiftkiqClient: Client {
    public let store: ListStorable
    
    static var `default`: Client = SwiftkiqClient(store: MockStore())
    
    init(store: ListStorable) {
        self.store = store
    }
    
    public func enqueue<W: Worker, A: ArgumentType>(`class`: W.Type, argument: A, to queue: Queue) throws {
        self.store.enqueue(["class": `class`, "argument": argument], to: queue)
    }
}

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
    func enqueue<Worker: WorkerType, Argument: ArgumentType>(`class`: Worker.Type, argument: Argument, to queue: Queue) throws
}

public struct SwiftkiqClient: Client {
    public let store: ListStorable

    static var `default`: Client = SwiftkiqClient(store: SwiftkiqCore.store)

    init(store: ListStorable) {
        self.store = store
    }

    public func enqueue<Worker: WorkerType, A: ArgumentType>(`class`: Worker.Type, argument: A, to queue: Queue) throws {
        try self.store.enqueue(["jid": UUID().uuidString, "class": String(describing: `class`), "args": argument, "retry": 1], to: queue)
    }
}

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
    func enqueue<W: Worker, A: Argument>(`class`: W.Type, args: A, to queue: Queue) throws
}

public struct SwiftkiqClient: Client {
    public let store: ListStorable
    static var current: Client {
        if let client = instanceCache[Thread.current.name!] {
            return client
        }
        let store = SwiftkiqCore.makeStore()
        instanceCache[Thread.current.name!] = SwiftkiqClient(store: store)
        return instanceCache[Thread.current.name!]!
    }
    
    private static var instanceCache = Dictionary<String, Client>()

    init(store: ListStorable) {
        self.store = store
    }

    public func enqueue<W: Worker, A: Argument>(`class`: W.Type, args: A, to queue: Queue) throws {
        try self.store.enqueue(["jid": UUID().uuidString,
                                "class": String(describing: `class`),
                                "args": args.toDictionary(),
                                "retry": 1,
                                "queue": queue.name], to: queue)
    }
}

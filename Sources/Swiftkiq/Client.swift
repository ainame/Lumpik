//
//  Client.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Dispatch

public protocol Client {
    var store: ListStorable { get }
    func enqueue<W: Worker, A: Argument>(`class`: W.Type, args: A, to queue: Queue) throws
}

public struct SwiftkiqClient: Client {
    public let store: ListStorable
    
    private static let lock = NSLock()
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
    
    static func current(_ key: Int) -> Client {
        let k = String(key)
        lock.lock()
        defer { lock.unlock() }

        if let client = SwiftkiqClient.instanceCache[k] {
            return client
        }
        let store = SwiftkiqCore.makeStore()
        SwiftkiqClient.instanceCache[k] = SwiftkiqClient(store: store)
        return SwiftkiqClient.instanceCache[k]!
    }

}

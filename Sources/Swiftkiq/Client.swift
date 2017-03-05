//
//  Client.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Dispatch

fileprivate let lock = NSLock()
fileprivate let cacheKey = "tokyo.ainame.swiftkiq.client"
fileprivate var instanceCache = Dictionary<String, SwiftkiqClient>()

public struct SwiftkiqClient {
    public static var current: SwiftkiqClient {
        lock.lock()
        defer { lock.unlock() }
        
        if let client = Thread.current.threadDictionary[cacheKey] as? SwiftkiqClient {
            return client
        }

        let store = RedisStore.makeStore()
        Thread.current.threadDictionary[cacheKey] = SwiftkiqClient(store: store)
        return Thread.current.threadDictionary[cacheKey] as! SwiftkiqClient
    }

    public var store: Storable

    init(store: Storable) {
        self.store = store
    }

    public func enqueue<W: Worker, A: Argument>(`class`: W.Type, args: A, retry: Int = W.defaultRetry, to queue: Queue = W.defaultQueue) throws {
        try self.store.enqueue(["jid": UUID().uuidString,
                                "class": String(describing: `class`),
                                "args": args.toDictionary(),
                                "retry": retry,
                                "queue": queue.name], to: queue)
    }
}

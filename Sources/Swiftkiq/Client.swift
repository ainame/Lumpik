//
//  Client.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Dispatch

fileprivate let cacheKey = "tokyo.ainame.swiftkiq.client"
fileprivate var instanceCache = Dictionary<String, SwiftkiqClient>()

public struct SwiftkiqClient {
    private static let mutex = Mutex()
    
    public static var current: SwiftkiqClient {
        return mutex.synchronize { () -> SwiftkiqClient in
            if let store = Thread.current.threadDictionary[cacheKey] as? Storable {
                return SwiftkiqClient(store: store)
            }
            
            let store = RedisStore.makeStore()
            Thread.current.threadDictionary[cacheKey] = store
            return SwiftkiqClient(store: store)
        }
    }

    public var store: Storable

    init(store: Storable) {
        self.store = store
    }

    public func enqueue<W: Worker, A: Argument>(`class`: W.Type, args: A, retry: Int = W.defaultRetry, to queue: Queue = W.defaultQueue) throws {
        try self.store.enqueue(["jid": JobIdentityGenerator.makeIdentity().rawValue,
                                "class": String(describing: `class`),
                                "args": args.toDictionary(),
                                "retry": retry,
                                "queue": queue.name], to: queue)
    }
    
    public func enqueue(_ job: [String: Any], to queue: Queue = Queue("default")) throws {
        var newJob = job
        newJob["jid"] = (job["jid"] != nil) ? job["jid"] : JobIdentityGenerator.makeIdentity().rawValue
        try self.store.enqueue(newJob, to: queue)
    }
}

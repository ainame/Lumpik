//
//  Client.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Dispatch

public struct SwiftkiqClient {
    private static let _connectionPool = ConnectionPool<RedisConnection>(maxCapactiy: 5)

    public static func enqueue<W: Worker, A: Argument>(`class`: W.Type, args: A, retry: Int = W.defaultRetry, to queue: Queue = W.defaultQueue) throws {
        _ = try SwiftkiqClient.connectionPool { conn in
            try conn.enqueue(["jid": JobIdentityGenerator.makeIdentity().rawValue,
                              "class": String(describing: `class`),
                              "args": args.toDictionary(),
                              "retry": retry,
                              "queue": queue.name], to: queue)
        }
    }
    
    public static func enqueue(_ job: [String: Any], to queue: Queue = Queue("default")) throws {
        var newJob = job
        newJob["jid"] = (job["jid"] != nil) ? job["jid"] : JobIdentityGenerator.makeIdentity().rawValue
        _ = try SwiftkiqClient.connectionPool { conn in
            try conn.enqueue(newJob, to: queue)
        }
    }
    
    public static func connectionPool<T>(handler: (Storable) -> T) throws -> T {
        return try _connectionPool.with { item in
            handler(item.connection)
        }
    }
    
    public static func connectionPool<T>(handler: (Storable) throws -> T) throws -> T {
        return try _connectionPool.with { item in
            try handler(item.connection)
        }
    }
}

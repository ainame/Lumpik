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
    static var connectionPool = AnyConnectablePool(Application.default.connectionPool)

    public static func enqueue<W: Worker, A: Argument>(`class`: W.Type, args: A, retry: Int = W.defaultRetry, to queue: Queue = W.defaultQueue) throws {
        _ = try connectionPool.with { conn in
            try conn.enqueue(["jid": JobIdentityGenerator.makeIdentity().rawValue,
                              "class": String(describing: `class`),
                              "args": args.toArray(),
                              "retry": retry,
                              "queue": queue.name,
                              "created_at": Date().timeIntervalSince1970,
                              "enqueued_at": Date().timeIntervalSince1970 ], to: queue)
        }
    }
    
    public static func enqueue(_ job: [String: Any], to queue: Queue = Queue("default")) throws {
        var newJob = job
        newJob["jid"] = (job["jid"] != nil) ? job["jid"] : JobIdentityGenerator.makeIdentity().rawValue
        _ = try connectionPool.with { conn in
            try conn.enqueue(newJob, to: queue)
        }
    }
}

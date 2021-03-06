//
//  Client.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Dispatch

public struct LumpikClient {
    static var connectionPoolForInternal = AnyConnectablePool(Application.default.connectionPoolForInternal)

    public static func enqueue<W: Worker, A: Argument>(`class`: W.Type, args: A, retry: Int = W.defaultRetry, to queue: Queue = W.defaultQueue, at: TimeInterval? = nil) throws {
        let now = Date()
        let work = UnitOfWork(jid: JobIdentityGenerator.makeIdentity(),
                               workerType: String(describing: `class`),
                               args: args.toArray(),
                               queue: queue,
                               createdAt: now.timeIntervalSince1970,
                               enqueuedAt: now.timeIntervalSince1970,
                               retryCount: nil, retriedAt: nil, retryQueue: nil, failedAt: nil,
                               errorMessage: nil, errorBacktrace: nil, backtrace: nil, retry: nil, dead: nil)
        
        _ = try connectionPoolForInternal.with { conn in
            if let at = at {
                let score = SortedSetScore.value(at)
                try conn.add(work, with: score, to: ScheduledSet())
            } else {
                try conn.enqueue(work, to: queue)
            }
        }
    }

    public static func enqueue(_ job: [String: Any], to queue: Queue? = nil) throws {
        let newQueue = queue ?? Queue(job["queue"] as! String)
        var newJob = job
        newJob["jid"] = (job["jid"] != nil) ? job["jid"] : JobIdentityGenerator.makeIdentity().rawValue
        _ = try connectionPoolForInternal.with { conn in
            try conn.enqueue(newJob, to: newQueue)
        }
    }

    public static func enqueue(_ job: UnitOfWork, to queue: Queue? = nil) throws {
        let newQueue = queue ?? job.queue
        _ = try connectionPoolForInternal.with { conn in
            try conn.enqueue(job, to: newQueue)
        }
    }
}

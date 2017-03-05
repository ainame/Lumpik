//
//  UnitOfWork.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/05.
//
//

import Foundation

public struct UnitOfWork {
    public let queue: Queue
    public let job: Dictionary<String, Any>

    public var jid: String { return job["jid"]! as! String }
    public var workerType: String { return job["class"]! as! String }
    public var args: Dictionary<String, Any> { return job["args"]! as! Dictionary<String, Any> }
    public var retry: Int { return Int(job["retry"]! as! UInt) }
    public var retryCount: Int? { return Int(job["retry_count"]! as! UInt) }
    public var retriedAt: String? { return job["retried_at"]! as? String }
    public var retryQueue: Queue? {
        guard let q = job["retry_queue"] else { return nil }
        return  Queue(rawValue: q as! String)
    }
    public var failedAt: String? { return job["failed_at"]! as? String }

    public init(queue: Queue, job: Dictionary<String, Any>) {
        self.queue = queue
        self.job = job
    }

    public func requeue() throws {
        // TODO
    }
}

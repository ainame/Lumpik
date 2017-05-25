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
    
    public let job: [String: Any]

    public var jid: Jid { return Jid(job["jid"]! as! String)! }
    
    public var workerType: String { return job["class"]! as! String }
    
    public var args: [Any] { return job["args"]! as! [Any] }
    
    // this behavior follow sidekiq's one
    public var retry: Int {
        switch job["retry"] {
        case _ as Bool:
            return 25
        case let x as UInt:
            return Int(x)
        default:
            return 25
        }
    }
    
    public var retryCount: Int? {
        guard let retryCount = job["retry_count"] as? Int else { return nil }
        return retryCount
    }
    
    public var retriedAt: String? {
        guard let retriedAt = job["retried_at"] as? String else { return nil }
        return retriedAt
    }
    
    public var retryQueue: Queue? {
        guard let q = job["retry_queue"] else { return nil }
        return  Queue(rawValue: q as! String)
    }
    
    public var failedAt: String? {
        guard let failedAt = job["failed_at"] as? String else { return nil }
        return failedAt
    }

    public init(queue: Queue, job: [String: Any]) {
        self.queue = queue
        self.job = job
    }

    public func requeue() throws {
        // TODO
    }
}

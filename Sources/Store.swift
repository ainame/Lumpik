//
//  Store.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Redbird

public struct UnitOfWork {
    let queue: Queue
    
    var jid: String { return job["jid"]! as! String }
    var jobClass: String { return job["jobClass"]! as! String }
    var workerClass: String { return job["workerClass"]! as! String }
    var argument: Dictionary<String, Any> { return job["argument"]! as! Dictionary<String, Any> }
    var retry: Int { return job["retry"]! as! Int }
    
    private let job: Dictionary<String, Any>
    
    public init(queue: Queue, job: Dictionary<String, Any>) {
        self.queue = queue
        self.job = job
    }
    
    func requeue() throws {
        // TODO
    }
}

public protocol ListStorable {
    func enqueue(_ job: Dictionary<String, Any>, to queue: Queue) throws
    func dequeue(_ queue: Queue) throws -> UnitOfWork?
}

final class RedisStore: ListStorable {
    let host: String
    let port: UInt16
    let timeout: String = "2"
    
    private let redis: Redbird
    private let helper: JsonHelper
    
    init(host: String, port: UInt16) throws {
        self.host = host
        self.port = port
        self.redis = try Redbird(config: .init(address: host, port: port, password: nil))
        self.helper = JsonHelper()
    }
    
    public func enqueue(_ job: Dictionary<String, Any>, to queue: Queue) throws {
        let string = helper.serialize(job)
        try redis.command("LPUSH", params: [queue.name, string])
    }

    func dequeue(_ queue: Queue) throws -> UnitOfWork? {
        let response = try redis.command("BRPOP", params: [queue.name, timeout])
        guard response.respType == .Array else { return nil }
        
        let dict = helper.deserialize(response)
        return UnitOfWork(queue: queue, job: dict)
    }
}

final class MockStore: ListStorable {
    private var all = Dictionary<Queue, Array<Dictionary<String, Any>>>()
    
    public func dequeue(_ queue: Queue) throws -> UnitOfWork? {
        guard let job = all[queue]?.removeFirst() else {
            return nil
        }
        
        return UnitOfWork(queue: queue, job: job)
    }
    
    public func enqueue(_ job: Dictionary<String, Any>, to queue: Queue) throws {
        if var list = all[queue] {
            list.append(job)
        } else {
            var list = Array<Dictionary<String, Any>>()
            list.append(job)
            all[queue] = list
        }
    }
}

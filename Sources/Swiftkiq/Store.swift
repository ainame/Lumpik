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
    func dequeue(_ queues: [Queue]) throws -> UnitOfWork?
}

final public class RedisStore: ListStorable {
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

    public func dequeue(_ queues: [Queue]) throws -> UnitOfWork? {
        let queusCommand = queues.map { $0.rawValue }.joined(separator: " ")
        let response = try redis.command("BRPOP", params: [queusCommand, timeout])
        guard response.respType == .Array else { return nil }
        
        let parsedResponse = helper.deserialize(response) as! Array<Any>
        let queueStr = parsedResponse[0] as! String
        let dictionary = parsedResponse[1] as! Dictionary<String, Any>
        return UnitOfWork(queue: Queue(rawValue: queueStr), job: dictionary)
    }
}

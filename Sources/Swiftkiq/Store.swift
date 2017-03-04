//
//  Store.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import SwiftRedis

public struct UnitOfWork {
    public let queue: Queue

    public var jid: String { return job["jid"]! as! String }
    public var workerClass: String { return job["class"]! as! String }
    public var args: Dictionary<String, Any> { return job["args"]! as! Dictionary<String, Any> }
    public var retry: Int { return Int(job["retry"]! as! UInt) }

    private let job: Dictionary<String, Any>

    public init(queue: Queue, job: Dictionary<String, Any>) {
        self.queue = queue
        self.job = job
    }

    public func requeue() throws {
        // TODO
    }
}

public protocol ListStorable {
    func enqueue(_ job: Dictionary<String, Any>, to queue: Queue) throws
    func dequeue(_ queues: [Queue]) throws -> UnitOfWork?
    func clear(_ queue: Queue) throws
}

final public class RedisStore: ListStorable {
    let host: String
    let port: UInt16
    let timeout: TimeInterval = 2.0

    private let redis: Redis
    private let helper: JsonHelper

    init(host: String, port: UInt16) throws {
        self.host = host
        self.port = port
        self.redis = Redis()
        self.helper = JsonHelper()

        var error: NSError? = nil
        redis.connect(host: host, port: Int32(port), callback: { _error in
            error = _error
        })
        if let error = error {
            throw error
        }
    }
    
    public func enqueue(_ job: Dictionary<String, Any>, to queue: Queue) throws {
        let string = helper.serialize(job)
        var error: NSError? = nil
        redis.lpush(queue.key, values: string, callback: { count, _error in
            error = _error
        })
        if let error = error {
            throw error
        }
    }

    public func dequeue(_ queues: [Queue]) throws -> UnitOfWork? {
        var response: [RedisString?]?
        var error: NSError? = nil
        redis.brpop(queues.map{ $0.key }, timeout: timeout) { _response, _error in
            response = _response
            error = _error
        }
        if let error = error {
            throw error
        }
        guard let validResponse = response else { return nil }
        
        let parsedResponse = helper.deserialize(validResponse)
        let queue = Queue(rawValue: parsedResponse["queue"]! as! String)
        return UnitOfWork(queue: queue, job: parsedResponse)
    }
    
    public func clear(_ queue: Queue) throws {
        var error: NSError? = nil
        redis.del(queue.key, callback: { _count, _error in
            error = _error
        })
        if let error = error {
            throw error
        }
    }
}

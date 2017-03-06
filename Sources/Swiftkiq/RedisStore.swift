//
//  RedisStore.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/05.
//
//

import Foundation
import SwiftRedis

public struct RedisConfig {
    let host: String = "127.0.0.1"
    let port: Int = 6379
    let password: String? = nil
}

final public class RedisStore: Storable {
    static var defaultConfig = RedisConfig()
    
    public static func makeStore() -> Storable {
        return try! RedisStore(host: defaultConfig.host, port: UInt16(defaultConfig.port))
    }
    
    let host: String
    let port: UInt16
    let timeout: TimeInterval = 2.0
    
    private let redis: Redis
    
    init(host: String, port: UInt16) throws {
        self.host = host
        self.port = port
        self.redis = Redis()
        
        var error: NSError? = nil
        redis.connect(host: host, port: Int32(port)) { _error in
            error = _error
        }
        if let error = error {
            throw error
        }
    }
    
    public func enqueue(_ job: Dictionary<String, Any>, to queue: Queue) throws {
        let string = JsonHelper.serialize(job)
        var error: NSError? = nil
        redis.lpush(queue.key, values: string) { count, _error in
            error = _error
        }
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
        
        let parsedResponse = JsonHelper.deserialize(validResponse)
        let queue = Queue(rawValue: parsedResponse["queue"]! as! String)
        return UnitOfWork(queue: queue, job: parsedResponse)
    }
    
    public func clear<K: StoreKeyConvertible>(_ key: K) throws {
        var error: NSError? = nil
        redis.del(key.key) { _count, _error in
            error = _error
        }
        if let error = error {
            throw error
        }
    }
    
    public func add(_ job: Dictionary<String, Any>, to set: Set) throws {
        let string = JsonHelper.serialize(job)
        var error: NSError? = nil
        redis.sadd(set.key, members: string) { _count, _error in
            error = _error
        }
        if let error = error {
            throw error
        }
    }
    
    public func members(_ set: Set) throws -> [Dictionary<String, Any>] {
        var members: [Any]? = nil
        var error: NSError? = nil
        redis.smembers(set.key) { _members, _error in
            members = _members
            error = _error
        }
        if let error = error {
            throw error
        }
        return members as! [Dictionary<String, Any>]
    }

    public func size(_ set: Set) throws -> Int {
        var count: Int? = nil
        var error: NSError? = nil
        redis.scard(set.key) { _count, _error in
            count = _count
            error = _error
        }
        if let error = error {
            throw error
        }
        return count!
    }

    public func add(_ job: Dictionary<String, Any>, with score: Int, to set: SortedSet) throws {
        let string = JsonHelper.serialize(job)
        var error: NSError? = nil
        redis.zadd(set.key, tuples: (score, string)) { _count, _error in
            error = _error
        }
        if let error = error {
            throw error
        }
    }

    public func size(_ sortedSet: SortedSet) throws -> Int {
        var count: Int? = nil
        var error: NSError? = nil
        redis.zcard(sortedSet.key) { _count, _error in
            count = _count
            error = _error
        }
        if let error = error {
            throw error
        }
        return count!
    }
}

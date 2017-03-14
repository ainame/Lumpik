//
//  RedisStore.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/05.
//
//

import Foundation
import Redbird
import Mapper

public struct RedisConfig {
    let host: String = "127.0.0.1"
    let port: Int = 6379
    let password: String? = nil
}

public struct PipelineTransaction: Transaction {
    let pipeline: Pipeline

    public init(pipeline: Pipeline) {
        self.pipeline = pipeline
    }

    public func addCommand(_ name: String, params: [String]) throws -> PipelineTransaction {
        return try PipelineTransaction(pipeline: pipeline.enqueue(name, params: params))
    }

    public func exec() throws -> Bool {
        let responses = try pipeline.enqueue("EXEC").execute()
        guard try responses[0].toString() == "OK" else { return false }

        let quueingSuccessful = responses.map { $0.respType != .Error }.reduce(true) { $0 && $1 }
        guard quueingSuccessful else { return false }

        let transactionSuccessful = try responses[responses.count - 1]
            .toArray().map { $0.respType != .Error }.reduce(true) { $0 && $1 }
        guard transactionSuccessful else { return false }

        return true
    }
}

final public class RedisStore: Storable {
    typealias Redis = Redbird
    static var defaultConfig = RedisConfig()

    public static func makeStore() -> Storable {
        return try! RedisStore(host: defaultConfig.host, port: UInt16(defaultConfig.port))
    }

    let host: String
    let port: UInt16
    let timeout: Int = 2

    fileprivate let redis: Redis

    init(host: String, port: UInt16) throws {
        self.host = host
        self.port = port
        self.redis = try Redbird(config: RedbirdConfig(address: host, port: port, password: nil))
    }

    public func multi() throws -> Transaction {
        return PipelineTransaction(pipeline: try redis.pipeline().enqueue("MULTI"))
    }

    @discardableResult
    public func clear<K: StoreKeyConvertible>(_ key: K) throws -> Int {
        let response = try redis.command("DEL", params: [key.key])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toInt()
    }
}

extension RedisStore: ValueStorable {
    public func get<K: StoreKeyConvertible>(_ key: K) throws -> String? {
        let response = try redis.command("GET", params: [key.key])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .BulkString || response.respType == .NullBulkString))

        return try! response.toMaybeString()
    }

    public func set<K: StoreKeyConvertible>(_ key: K, value: String) throws -> Bool {
        let response = try redis.command("SET", params: [key.key, value])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toBool()
    }

    public func increment<K: StoreKeyConvertible>(_ key: K, by count: Int = 1) throws -> Int {
        let response = try redis.command("INCRBY", params: [key.key, String(count)])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toInt()
    }
}

extension RedisStore: ListStorable {
    @discardableResult
    public func enqueue(_ job: Dictionary<String, Any>, to queue: Queue) throws -> Int {
        let string = JsonHelper.serialize(job)
        let response = try redis.command("LPUSH", params: [queue.key, string])
        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toInt()
    }

    public func dequeue(_ queues: [Queue]) throws -> UnitOfWork? {
        var params = queues.map { $0.key }
        params.append(String(timeout))

        let response = try redis.command("BRPOP", params: params)
        guard response.respType != .Error else { throw try! response.toError() }
        assert(response.respType == .Array || response.respType == .NullArray)

        if response.respType == .NullArray {
            return nil
        }

        let responseArray = try! response.toArray()
        let queueName = try! responseArray[0].toString()
        let jsonString = try! responseArray[1].toString()
        let parsedJson = JsonHelper.deserialize(jsonString)
        let queue = Queue(queueName)
        return UnitOfWork(queue: queue, job: parsedJson)
    }
}

extension RedisStore: SetStorable {
    @discardableResult
    public func add(_ job: Dictionary<String, Any>, to set: Set) throws -> Int {
        let string = JsonHelper.serialize(job)
        let response = try redis.command("SADD", params: [string])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toInt()
    }

    public func members<T: Mappable>(_ set: Set) throws -> [T] {
        let response = try redis.command("SMEMBERS", params: [set.key])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Array))

        let members = try! response.toArray().map { try $0.toString() }
        var all = [T]()

        for member in members {
            let data = member.data(using: .utf8)!
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as! NSDictionary
            if let object = T.from(json) {
                all.append(object)
            }
        }

        return all
    }

    public func size(_ set: Set) throws -> Int {
        let response = try redis.command("SCARD", params: [set.key])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toInt()
    }
}

extension RedisStore: SortedSetStorable {
    @discardableResult
    public func add(_ job: Dictionary<String, Any>, with score: Int, to set: SortedSet) throws -> Int {
        let string = JsonHelper.serialize(job)
        let response = try redis.command("ZADD", params: [string, String(score)])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toInt()
    }

    public func size(_ sortedSet: SortedSet) throws -> Int {
        let response = try redis.command("ZCARD", params: [sortedSet.key])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toInt()
    }
}

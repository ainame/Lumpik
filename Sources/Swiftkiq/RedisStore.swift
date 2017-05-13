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
    let host: String = "localhost"
    let port: Int = 6379
    let password: String? = nil
}

public struct PipelineTransaction: Transaction {
    let pipeline: Pipeline

    public init(pipeline: Pipeline) {
        self.pipeline = pipeline
    }

    public func addCommand(_ name: String) throws -> PipelineTransaction {
        _ = try pipeline.enqueue(name)
        return self
    }

    public func addCommand(_ name: String, params: [String]) throws -> PipelineTransaction {
        _ = try pipeline.enqueue(name, params: params)
        return self
    }

    public func execute() throws -> [RespObject] {
        let responses = try pipeline.execute()

        let errors = try responses.flatMap { (resp: RespObject) in
            try(resp.respType == .Array ? resp.toArray() : [resp])
        }.filter { (resp: RespObject) in
            resp.respType == .Error
        }.map { (resp: RespObject) in
            try resp.toError()
        }
        if let error = errors.first {
            throw error
        }

        return responses
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
    fileprivate let converter: Converter = JsonConverter.default

    init(host: String, port: UInt16) throws {
        self.host = host
        self.port = port
        self.redis = try Redbird(config: RedbirdConfig(address: host, port: port, password: nil))
    }

    public func pipelined() -> Transaction {
        return PipelineTransaction(pipeline: redis.pipeline())
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

    public func set<K: StoreKeyConvertible>(_ key: K, value: String) throws -> Int {
        let response = try redis.command("SET", params: [key.key, value])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toInt()
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
    public func enqueue(_ job: [String: Any], to queue: Queue) throws -> Int {
        let string = JsonConverter.default.serialize(job)
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
        let jsonString = try! responseArray[1].toString()
        let parsedJson = converter.deserialize(dictionary: jsonString)
        let queue = Queue(parsedJson["queue"]! as! String)
        return UnitOfWork(queue: queue, job: parsedJson)
    }
}

extension RedisStore: SetStorable {
    public func add(_ member: [String: Any], to set: Set) throws -> Int {
        let string = converter.serialize(member)
        let response = try redis.command("SADD", params: [set.key, string])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toInt()
    }

    public func remove(_ members: [String], from set: Set) throws -> Int {
        var params = [set.key]
        members.forEach { params.append($0) }

        let response = try redis.command("SREM", params: params)

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toInt()
    }

    public func members(_ set: Set) throws -> [String] {
        let response = try redis.command("SMEMBERS", params: [set.key])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Array))

        let members = try! response.toArray().map { try $0.toString() }
        return members
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
    public func add(_ member: [String: Any], with score: SortedSetScore, to sortedSet: SortedSet) throws -> Int {
        let string = converter.serialize(member)
        let response = try redis.command("ZADD", params: [sortedSet.key, score.string, string])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toInt()
    }

    @discardableResult public func remove(_ members: [String], from sortedSet: SortedSet) throws -> Int {
        var params = [sortedSet.key]
        members.forEach { params.append($0) }
        let response = try redis.command("ZREM", params: params)

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toInt()
    }

    public func range(min: SortedSetScore, max: SortedSetScore, from sortedSet: SortedSet, offset: Int, count: Int) throws -> [[String: Any]] {
        let params = [sortedSet.key, min.string, max.string, "LIMIT", String(offset), String(count)]
        let response = try redis.command("ZRANGEBYSCORE", params: params)
        guard response.respType != .Error else { throw try! response.toError() }

        return try! response.toArray().map { try! $0.toString() }.map { converter.deserialize(dictionary: $0) }
    }

    public func size(_ sortedSet: SortedSet) throws -> Int {
        let response = try redis.command("ZCARD", params: [sortedSet.key])

        guard response.respType != .Error else { throw try! response.toError() }
        assert((response.respType == .Integer))

        return try! response.toInt()
    }
}

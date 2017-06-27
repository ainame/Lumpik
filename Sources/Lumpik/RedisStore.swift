//
//  RedisStore.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/03/05.
//
//

import Foundation
import Redis
import Sockets

public struct RedisConfig {
    public let host: String = "localhost"
    public let port: Int = 6379
    public let password: String? = nil
}

public final class RedisStore: Connectable {
    public static var defaultConfig = RedisConfig()

    public static func makeStore() throws -> RedisStore {
        return try RedisStore(host: defaultConfig.host, port: UInt16(defaultConfig.port))
    }

    public static func makeConnection() throws -> RedisStore {
        return try RedisStore(host: defaultConfig.host, port: UInt16(defaultConfig.port))
    }

    public func releaseConnection() throws {
    }

    let host: String
    let port: UInt16
    let password: String?
    let dequeueTimeout = 2
    let defaultTimeout = 8.0

    fileprivate let redis: Redis.TCPClient
    
    init(host: String, port: UInt16, password: String? = nil) throws {
        self.host = host
        self.port = port
        self.password = password
        self.redis = try Redis.TCPClient(hostname: host, port: port, password: password)
        try self.redis.stream.setTimeout(defaultTimeout)
    }
    
    @discardableResult
    func clear<K: StoreKeyConvertible>(_ key: K) throws -> Int {
        let response = try redis.command(.delete, [key.key])
        return response!.int!
    }
}

extension RedisStore {
    func get<K: StoreKeyConvertible>(_ key: K) throws -> String? {
        let response = try redis.command(.get, [key.key])
        return response?.string
    }

    func set<K: StoreKeyConvertible>(_ key: K, value: String) throws -> Int {
        let response = try redis.command(.set, [key.key, value.makeBytes()])
        return response!.int!
    }

    func increment<K: StoreKeyConvertible>(_ key: K, by count: Int = 1) throws -> Int {
        let response = try redis.command(Command("INCRBY"), [key.key, String(count).makeBytes()])
        return response!.int!
    }
}

extension RedisStore {
    @discardableResult
    func enqueue(_ job: [String: Any], to queue: Queue) throws -> Int {
        let data = try JsonConverter.default.serialize(job)
        let response = try redis.command(Command("LPUSH"), [queue.key, data.makeBytes()])
        return response!.int!
    }
    
    @discardableResult
    func enqueue(_ job: UnitOfWork, to queue: Queue) throws -> Int {
        let data = try JSONEncoder().encode(job)
        let response = try redis.command(Command("LPUSH"), [queue.key, data.makeBytes()])
        return response!.int!
    }

    func dequeue(_ queues: [Queue]) throws -> UnitOfWork? {
        var params = queues.map { $0.key }
        params.append(String(dequeueTimeout).makeBytes())

        let response = try redis.command(Command("BRPOP"), params)
        guard let array = response?.array else {
            return nil
        }
        
        let data = Data(array[1]!.bytes!)
        return try JSONDecoder().decode(UnitOfWork.self, from: data)
    }
    
    func size(_ queue: Queue) throws -> Int {
        let response = try redis.command(Command("LLEN"), [queue.key])
        return response!.int!
    }
}

extension RedisStore {
    func add(_ member: [String: Any], to set: Set) throws -> Int {
        let data = try JSONEncoder().encode(member)
        let response = try redis.command(Command("SADD"), [set.key, data.makeBytes()])
        return response!.int!
    }

    func remove(_ members: [String], from set: Set) throws -> Int {
        var params = [set.key]
        members.forEach { params.append($0.makeBytes()) }

        let response = try redis.command(Command("SREM"), params)
        return response!.int!
    }

    func members(_ set: Set) throws -> [String] {
        let response = try redis.command(Command("SMEMBERS"), [set.key])
        let members: [String] = response!.array!.flatMap { $0!.string! }
        return members
    }

    public func size(_ set: Set) throws -> Int {
        let response = try redis.command(Command("SCARD"), [set.key])
        return response!.int!
    }
}

extension RedisStore {
    @discardableResult
    func add(_ member: UnitOfWork, with score: SortedSetScore, to sortedSet: SortedSet) throws -> Int {
        let data = try JSONEncoder().encode(member)
        let response = try redis.command(Command("ZADD"), [sortedSet.key, score.string.makeBytes(), data.makeBytes()])
        return response!.int!
    }

    @discardableResult public func remove(_ members: [String], from sortedSet: SortedSet) throws -> Int {
        var params = [sortedSet.key]
        members.forEach { params.append($0.makeBytes()) }
        let response = try redis.command(Command("ZREM"), params)
        return response!.int!
    }

    func range(min: SortedSetScore, max: SortedSetScore, from sortedSet: SortedSet, offset: Int, count: Int) throws -> [UnitOfWork] {
        let params = [sortedSet.key, min.string.makeBytes(), max.string.makeBytes(),
                      "LIMIT".makeBytes(), String(offset).makeBytes(), String(count).makeBytes()]
        let response = try redis.command(Command("ZRANGEBYSCORE"), params)
        let decoder = JSONDecoder()
        return try response!.array!.flatMap { $0!.string }
            .map { try decoder.decode(UnitOfWork.self, from: Data($0.makeBytes())) }
    }

    func size(_ sortedSet: SortedSet) throws -> Int {
        let response = try redis.command(Command("ZCARD"), [sortedSet.key])
        return response!.int!
    }
}

extension RedisStore {
    func pipelined() -> Redis.Pipeline<TCPInternetSocket> {
        return redis.makePipeline()
    }
    
    static func verify(pipelinedResponses: [Redis.Data?]) -> (successes: [Redis.Data?], errors: [Error]) {
        // workaround swift3's bug
        var successes = Array<Redis.Data?>()
        var errors = [Error]()
        
        for response in pipelinedResponses {
            if let response = response {
                switch response {
                case .error(let error):
                    errors.append(error)
                default:
                    successes.append(response)
                }
            } else {
                successes.append(response)
            }
        }
        
        return (successes: successes, errors: errors)
    }
}

enum SortedSetScore {
    case value(Double)
    case infinityPositive
    case infinityNegative
    
    var string: String {
        switch self {
        case .value(let double):
            return String(double)
        case .infinityPositive:
            return "+Inf"
        case .infinityNegative:
            return "-Inf"
        }
    }
}

extension StoreKeyConvertible where Self.RawValue == String {
    var name: String {
        return rawValue
    }
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
}

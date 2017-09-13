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
    public let host: String
    public let port: Int
    public let password: String?
    
    public init(host: String = "localhost", port: Int = 6379, password: String? = nil) {
        self.host = host
        self.port = port
        self.password = password
    }
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

    public let host: String
    public let port: UInt16
    public let password: String?
    public let dequeueTimeout = 2
    public let defaultTimeout = 8.0

    fileprivate let redis: Redis.TCPClient
    
    public init(host: String, port: UInt16, password: String? = nil) throws {
        self.host = host
        self.port = port
        self.password = password
        self.redis = try Redis.TCPClient(hostname: host, port: port, password: password)
        try self.redis.stream.setTimeout(defaultTimeout)
    }
    
    @discardableResult
    public func clear<K: StoreKeyConvertible>(_ key: K) throws -> Int {
        let response = try redis.command(.delete, [key.key])
        return response!.int!
    }
}

extension RedisStore {
    public func keys(_ key: String) throws -> [String] {
        return try redis.command(Command("KEYS"), [key.makeBytes()])!.array!.map { $0!.string! }
    }
    
    public func get(_ key: String) throws -> String? {
        return try redis.command(.get, [key])?.string
    }
    
    public func mget(_ keys: [String]) throws -> [String?] {
        return try redis.command(Command("MGET"), keys.map { $0.makeBytes() })!.array!.map { $0!.string }
    }
  
    public func set<K: StoreKeyConvertible>(_ key: K, value: String) throws -> Bool {
        return try set(key.key, value: value)
    }
    
    public func set(_ key: String, value: String) throws -> Bool {
        let response = try redis.command(.set, [key.bytes, value.makeBytes()])
        return response?.string == "OK"
    }
    
    public func delete(_ key: String) throws -> Int {
        let response = try redis.command(.delete, [key.bytes])
        return response!.int!
    }
   
    public func increment<K: StoreKeyConvertible>(_ key: K, by count: Int = 1) throws -> Int {
        return try increment(key.key, by: count)
    }
    
    public func increment(_ key: String, by count: Int = 1) throws -> Int {
        let response = try redis.command(Command("INCRBY"), [key.bytes, String(count).makeBytes()])
        return response!.int!
    }

}

extension RedisStore {
    @discardableResult
    public func enqueue(_ job: [String: Any], to queue: Queue) throws -> Int {
        return try enqueue(job, to: queue.key)
    }
    
    public func enqueue(_ job: [String: Any], to key: String) throws -> Int {
        let data = try JsonConverter.default.serialize(job)
        let response = try redis.command(Command("LPUSH"), [key.bytes, data.makeBytes()])
        return response!.int!
    }
    
    @discardableResult
    public func enqueue<T: Encodable>(_ job: T, to queue: Queue) throws -> Int {
        let data = try JSONEncoder().encode(job)
        let response = try redis.command(Command("LPUSH"), [queue.key.makeBytes() , data.makeBytes()])
        return response!.int!
    }

    public func dequeue(_ queues: [Queue]) throws -> UnitOfWork? {
        let decoder = JSONDecoder()
        guard let response = try dequeue(queues.map { $0.key }) else { return nil }
        return try decoder.decode(UnitOfWork.self, from: response.value.data(using: .utf8)!)
    }

    public func dequeue(_ queues: [String]) throws -> (key: String, value: String)? {
        var params = queues.map { $0.bytes }
        params.append(String(dequeueTimeout).makeBytes())
        
        let response = try redis.command(Command("BRPOP"), params)
        guard let array = response?.array else { return nil }

        return (key: array[0]!.string!, value: array[1]!.string!)
    }

    public func size(_ queue: Queue) throws -> Int {
        return try size(queuekey: queue.key)
    }
    
    public func size(queuekey: String) throws -> Int {
        let response = try redis.command(Command("LLEN"), [queuekey])
        return response!.int!
    }
}

extension RedisStore {
    public func add(_ member: [String: Any], to set: Set) throws -> Int {
        return try add(member, to: set.key)
    }
    
    public func add(_ member: [String: Any], to key: String) throws -> Int {
        let data = try JSONEncoder().encode(member)
        let response = try redis.command(Command("SADD"), [key.bytes, data.makeBytes()])
        return response!.int!
    }

    @discardableResult
    public func remove(_ members: [String], from set: Set) throws -> Int {
        return try remove(members, fromSet: set.key)
    }

    @discardableResult
    public func remove(_ members: [String], fromSet key: String) throws -> Int {
        var params = [key.bytes]
        members.forEach { params.append($0.makeBytes()) }
        
        let response = try redis.command(Command("SREM"), params)
        return response!.int!
    }
    
    public func members(_ set: Set) throws -> [String] {
        return try members(set.key)
    }
    
    public func members(_ key: String) throws -> [String] {
        let response = try redis.command(Command("SMEMBERS"), [key.bytes])
        let members: [String] = try response!.array!.flatMap { $0!.string! }
        return members
    }

    public func size(_ set: Set) throws -> Int {
        return try size(setkey: set.key)
    }
    
    public func size(setkey key: String) throws -> Int {
        let response = try redis.command(Command("SCARD"), [key.bytes])
        return response!.int!
    }
}

extension RedisStore {
    @discardableResult
    public func add<T: Encodable>(_ member: T, with score: SortedSetScore, to sortedSet: SortedSet) throws -> Int {
        return try add(member, with: score, to: sortedSet.key)
    }
    
    public func add<T: Encodable>(_ member: T, with score: SortedSetScore, to key: String) throws -> Int {
        let data = try JSONEncoder().encode(member)
        let response = try redis.command(Command("ZADD"), [key.bytes, score.string.makeBytes(), data.makeBytes()])
        return response!.int!
    }

    @discardableResult
    public func remove(_ members: [String], from sortedSet: SortedSet) throws -> Int {
        return try remove(members, fromSortedSort: sortedSet.key)
    }
    
    @discardableResult
    public func remove(_ members: [String], fromSortedSort key: String) throws -> Int {
        var params = [key.bytes]
        members.forEach { params.append($0.makeBytes()) }
        let response = try redis.command(Command("ZREM"), params)
        return response!.int!
    }

    public func range<T: Decodable>(min: SortedSetScore, max: SortedSetScore,
                                    from sortedSet: SortedSet, offset: Int, count: Int) throws -> [T] {
        return try range(min: min, max: max, from: sortedSet.key, offset: offset, count: count)
    }
    
    public func range<T: Decodable>(min: SortedSetScore, max: SortedSetScore,
                                    from key: String, offset: Int, count: Int) throws -> [T] {
        let params = [key.bytes, min.string.makeBytes(), max.string.makeBytes(),
                      "LIMIT".makeBytes(), String(offset).makeBytes(), String(count).makeBytes()]
        let response = try redis.command(Command("ZRANGEBYSCORE"), params)
        let decoder = JSONDecoder()
        return try response!.array!.flatMap { try decoder.decode(T.self, from: $0!.string!.data(using: .utf8)!) }
    }

    public func size(_ sortedSet: SortedSet) throws -> Int {
        return try size(sortedSetkey: sortedSet.key)
    }
    
    public func size(sortedSetkey key: String) throws -> Int {
        let response = try redis.command(Command("ZCARD"), [key.bytes])
        return response!.int!
    }
}

extension RedisStore {
    public func pipelined() -> Redis.Pipeline<TCPInternetSocket> {
        return redis.makePipeline()
    }
    
    static public func verify(pipelinedResponses: [Redis.Data?]) -> (successes: [Redis.Data?], errors: [Error]) {
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

public enum SortedSetScore {
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

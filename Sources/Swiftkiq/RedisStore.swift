//
//  RedisStore.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/05.
//
//

import Foundation
import Sockets
import Redis
import Mapper

public struct RedisConfig {
    let host: String = "127.0.0.1"
    let port: Int = 6379
    let password: String? = nil
}

public struct PipelineTransaction: Transaction {
    let pipeline: Pipeline<TCPInternetSocket>

    public init(pipeline: Pipeline<TCPInternetSocket>) {
        self.pipeline = pipeline
    }

    public func addCommand(_ name: String, params: [String]) throws -> PipelineTransaction {
        let _ = try pipeline.enqueue(Command(name), params: params.map { $0.makeBytes() })
        return self
    }

    public func exec() throws -> Bool {
        let responses = try pipeline.enqueue(Command("EXEC")).execute().array
        guard responses[0]?.string == "OK" else { return false }
        return true
    }
}

final public class RedisStore: Storable {
    typealias Redis = TCPClient
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
        self.redis = try Redis(hostname: host, port: port, password: nil)
    }

    public func multi() throws -> Transaction {
        return PipelineTransaction(pipeline: try redis.makePipeline().enqueue(Command("MULTI")))
    }

    @discardableResult
    public func clear<K: StoreKeyConvertible>(_ key: K) throws -> Int {
        let response = try redis.command(.delete, [key.key.makeBytes()])
        return response!.int!
    }
}

extension RedisStore: ValueStorable {
    public func get<K: StoreKeyConvertible>(_ key: K) throws -> String? {
        let response = try redis.command(.get, [key.key.makeBytes()])
        return response!.string!
    }

    public func set<K: StoreKeyConvertible>(_ key: K, value: String) throws -> Bool {
        let response = try redis.command(.set, [key.key.makeBytes(), value.makeBytes()])
        return response!.bool!
    }

    public func increment<K: StoreKeyConvertible>(_ key: K, by count: Int = 1) throws -> Int {
        let response = try redis.command(Command("INCRBY"), [key.key.makeBytes(), String(count).makeBytes()])
        return response!.int!
    }
}

extension RedisStore: ListStorable {
    @discardableResult
    public func enqueue(_ job: Dictionary<String, Any>, to queue: Queue) throws -> Int {
        let string = JsonConverter.default.serialize(job)
        let response = try redis.command(Command("LPUSH"), [queue.key.makeBytes(), string.makeBytes()])
        return response!.int!
    }

    public func dequeue(_ queues: [Queue]) throws -> UnitOfWork? {
        var params = queues.map { $0.key }
        params.append(String(timeout))

        let response = try redis.command(Command("BRPOP"), params.map{ $0.makeBytes() })
        if let responseArray = response?.array {
            let jsonString = responseArray[1]!.string!
            let parsedJson = converter.deserialize(dictionary: jsonString)
            let queue = Queue(parsedJson["queue"]! as! String)
            return UnitOfWork(queue: queue, job: parsedJson)
        }
        return nil
    }
}

extension RedisStore: SetStorable {
    @discardableResult
    public func add(_ job: Dictionary<String, Any>, to set: Set) throws -> Int {
        let string = converter.serialize(job)
        let response = try redis.command(Command("SADD"), [string.makeBytes()])
        return response!.int!
    }

    public func members<T: JsonConvertible>(_ set: Set) throws -> [T] {
        let response = try redis.command(Command("SMEMBERS"), [set.key.makeBytes()])
        let members = response!.array!.map { $0!.string! }
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
        let response = try redis.command(Command("SCARD"), [set.key.makeBytes()])
        return response!.int!
    }
}

extension RedisStore: SortedSetStorable {
    @discardableResult
    public func add(_ job: Dictionary<String, Any>, with score: Int, to set: SortedSet) throws -> Int {
        let string = converter.serialize(job)
        let response = try redis.command(Command("ZADD"), [string.makeBytes(), String(score).makeBytes()])
        return response!.int!
    }

    public func size(_ sortedSet: SortedSet) throws -> Int {
        let response = try redis.command(Command("ZCARD"), [sortedSet.key.makeBytes()])
        return response!.int!
    }
}

//
//  Store.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Redbird
import Jay

public struct UnitOfWork {
    let queue: Queue
    let job: Dictionary<String, Any>
    
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
    private let jsonParser: Jay
    
    init(host: String, port: UInt16) throws {
        self.host = host
        self.port = port
        self.redis = try Redbird(config: .init(address: host, port: port, password: nil))
        self.jsonParser = Jay(formatting: .minified, parsing: .none)
    }
    
    public func enqueue(_ job: Dictionary<String, Any>, to queue: Queue) throws {
        let json = try jsonParser.dataFromJson(anyDictionary: job)
        let string = String(bytes: json, encoding: .utf8)!
        try redis.command("LPUSH", params: [queue.name, string])
    }

    func dequeue(_ queue: Queue) throws -> UnitOfWork? {
        let response = try redis.command("BRPOP", params: [queue.name, timeout])
        guard response.respType == .Array else { return nil }
        
        let array = try response.toArray()
        precondition(try! array[0].toString() == queue.name)
        
        guard let string = try array[1].toMaybeString()?.utf8 else { return nil }
        let json = try jsonParser.anyJsonFromData(Array<UInt8>(string))
        let dict = json as! Dictionary<String, Any>
        
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

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
        let queuesCommand = queues.map { $0.name }.joined(separator: " ")
        let response = try redis.command("BRPOP", params: [queuesCommand, timeout])
        guard response.respType == .Array else { return nil }

        let parsedResponse = helper.deserialize(response)
        let queue = Queue(rawValue: parsedResponse["queue"]! as! String)
        return UnitOfWork(queue: queue, job: parsedResponse)
    }
}

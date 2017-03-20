//
//  State.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/18.
//
//

import Foundation
import Mapper

public struct Process: JsonConvertible {
    let identity: ProcessIdentity
    let hostname: String
    let startedAt: Date
    let pid: Int
    let tag: String
    let concurrency: Int
    let queues: [Queue]
    let labels: [String]
    
    init(identity: ProcessIdentity, hostname: String, startedAt: Date, pid: Int,
         tag: String, concurrency: Int, queues: [Queue],
         labels: [String]) {
        self.identity = identity
        self.hostname = hostname
        self.startedAt = startedAt
        self.pid = pid
        self.tag = tag
        self.concurrency = concurrency
        self.queues = queues
        self.labels = labels
    }
    
    public init(map: Mapper) throws {
        self.identity = try map.from("identity")
        self.hostname = try map.from("hostname")
        self.startedAt = try map.from("started_at") { Date(timeIntervalSince1970: $0 as! TimeInterval) }
        self.pid = try map.from("pid")
        self.tag = try map.from("tag")
        self.concurrency = try map.from("concurrency")
        self.queues = try map.from("queues")
        self.labels = try map.from("labels")
    }
    
    public var asDictionary: [String : Any] {
        return [
            "identity": identity.rawValue,
            "hostname": hostname,
            "started_at": startedAt.timeIntervalSince1970,
            "pid": pid,
            "tag": tag,
            "concurrency": concurrency,
            "queues": queues.map { $0.rawValue },
            "labels": labels,
        ]
    }
}
public struct ProcessState: JsonConvertible {
    let info: Process?
    let busy: Int?
    let beat: Date?
    let quit: Bool

    public init(info: Process?, busy: Int?, beat: Date?, quit: Bool = false) {
        self.info = info
        self.busy = busy
        self.beat = beat
        self.quit = quit
    }
    
    public init(map: Mapper) throws {
        self.info = map.optionalFrom("info")
        self.busy = map.optionalFrom("busy")
        self.beat = map.optionalFrom("beat")
        self.quit = map.optionalFrom("quit") ?? false
    }
    
    public var asDictionary: [String : Any] {
        var base: [String : Any] = [
            "quit": quit
        ]
        
        if info != nil {
            base["info"] = info!.asDictionary
        }
        if busy != nil {
            base["busy"] = busy!
        }
        if beat != nil {
            base["beat"] = beat!.timeIntervalSince1970
        }

        return base
    }
}

public struct WorkerState: JsonConvertible {
    let work: UnitOfWork
    let runAt: Date
    
    public init(work: UnitOfWork, runAt: Date) {
        self.work = work
        self.runAt = runAt
    }
    
    public init(map: Mapper) throws {
        // avoid compile error
        let queue: Queue = try map.from("queue", transformation: Queue.fromMap)
        self.work = try map.from("payload") { UnitOfWork(queue: queue, job: $0 as! [String: Any]) }
        self.runAt = try map.from("run_at")
    }
    
    public var asDictionary: [String : Any] {
        return [
            "queue": work.queue.rawValue,
            "payload": work.job,
            "run_at": runAt.timeIntervalSince1970,
        ]
    }
}

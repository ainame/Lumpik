//
//  State.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/18.
//
//

import Foundation
import Mapper

struct ProcessState: JsonConvertible {
    let hostname: String
    let startedAt: Date
    let pid: Int
    let tag: String
    let concurrency: Int
    let queues: [Queue]
    let labels: [String]
    let identity: ProcessIdentity

    init(hostname: String, startedAt: Date, pid: Int,
         tag: String, concurrency: Int, queues: [Queue],
         labels: [String], identity: ProcessIdentity) {
        self.hostname = hostname
        self.startedAt = startedAt
        self.pid = pid
        self.tag = tag
        self.concurrency = concurrency
        self.queues = queues
        self.labels = labels
        self.identity = identity
    }
    
    init(map: Mapper) throws {
        self.hostname = try map.from("hostname")
        self.startedAt = try map.from("started_at") { Date(timeIntervalSince1970: $0 as! TimeInterval) }
        self.pid = try map.from("pid")
        self.tag = try map.from("tag")
        self.concurrency = try map.from("concurrency")
        self.queues = try map.from("queues")
        self.labels = try map.from("labels")
        self.identity = try map.from("identity")
    }
    
    var asDictionary: [String : Any] {
        return [
            "hostname": hostname,
            "started_at": startedAt.timeIntervalSince1970,
            "pid": pid,
            "tag": tag,
            "concurrency": concurrency,
            "queues": queues.map { $0.rawValue },
            "labels": labels,
            "identity": identity.rawValue,
        ]
    }
}

struct WorkerState: JsonConvertible {
    let work: UnitOfWork
    let runAt: Date
    
    init(work: UnitOfWork, runAt: Date) {
        self.work = work
        self.runAt = runAt
    }
    
    init(map: Mapper) throws {
        // avoid compile error
        let queue: Queue = try map.from("queue", transformation: Queue.fromMap)
        self.work = try map.from("payload") { UnitOfWork(queue: queue, job: $0 as! [String: Any]) }
        self.runAt = try map.from("run_at")
    }
    
    var asDictionary: [String : Any] {
        return [
            "queue": work.queue.rawValue,
            "payload": work.job,
            "run_at": runAt.timeIntervalSince1970,
        ]
    }
}

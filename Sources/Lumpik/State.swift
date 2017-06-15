//
//  State.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/03/18.
//
//

import Foundation

public struct Process: Codable {
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
    
    private enum CodingKeys: String, CodingKey {
        case identity, hostname, pid, tag, concurrency, queues, labels
        case startedAt = "started_at"
    }
}
public struct ProcessState: Codable {
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
}

public struct WorkerState: Codable {
    let queue: Queue
    let payload: UnitOfWork
    let runAt: Date
    
    public init(work: UnitOfWork, runAt: Date) {
        self.payload = work
        self.queue = work.queue
        self.runAt = runAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case queue, payload
        case runAt = "run_at"
    }
}

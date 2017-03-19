//
//  Api.swift
//  Swiftkiq
//
//  Created by satoshi.namai on 2017/03/06.
//
//

import Foundation
import Mapper

public struct Process: JsonConvertible {
    let hostname: String
    let startedAt: Date
    let pid: Int
    let tag: String
    let concurrency: Int
    let queues: [Queue]
    let busy: Int
    let beat: Date
    let identity: String

    public init(map: Mapper) throws {
        self.hostname = try map.from("hostname")
        self.startedAt = try map.from("started_at") { Date(timeIntervalSince1970: $0 as! TimeInterval) }
        self.pid = try map.from("pid")
        self.tag = try map.from("tag")
        self.concurrency = try map.from("concurrency")
        self.queues = try map.from("queues")
        self.busy = try map.from("busy")
        self.beat = try map.from("beat")
        self.identity = try map.from("identity")
    }
    
    public var asDictionary: [String : Any] {
        return [
            "hostname": hostname,
            "started_at": startedAt.timeIntervalSince1970,
            "pid": pid,
            "tag": tag,
            "concurrency": concurrency,
            "queues": queues,
            "busy": busy,
            "beat": beat,
            "identity": identity,
        ]
    }
}

public final class ProcessSet: Set {
    public convenience init() {
        self.init(rawValue: "processes")
    }
    
    func each(_ block: (Process) -> ()) throws {
        let processes: [Process] = try SwiftkiqClient.current.store.members(self).sorted { $0.hostname < $1.hostname }
        for process in processes {
            block(process)
        }
    }
    
    var count: Int {
        return (try? SwiftkiqClient.current.store.size(self)) ?? 0
    }
}

public class JobSet: SortedSet {
}

public final class ScheduledSet: JobSet {
    public convenience init() {
        self.init(rawValue: "scheduled")
    }
}

public final class RetrySet: JobSet {
    public convenience init() {
        self.init(rawValue: "retry")
    }
}

extension StoreKeyConvertible {
    public func clear() throws {
        try SwiftkiqClient.current.store.clear(self)
    }
    
    public func 💣() throws {
        try clear()
    }
}

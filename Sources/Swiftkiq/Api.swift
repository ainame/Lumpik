//
//  Api.swift
//  Swiftkiq
//
//  Created by satoshi.namai on 2017/03/06.
//
//

import Foundation
import Mapper

public final class ProcessSet: Set {
    public convenience init() {
        self.init(rawValue: "processes")
    }
    
    public static func cleanup() throws -> Int {
        let set = ProcessSet()
        let store = SwiftkiqClient.current.store
        let processes: [String] = try store.members(set)
        let pipeline = try store.pipelined()
        
        for processKey in processes {
            try pipeline.addCommand("HGET", params: [processKey, "info"])
        }
        
        let converter = JsonConverter.default
        let heartbeats = try pipeline.execute().flatMap { try? $0.toString() }.map { converter.deserialize(dictionary: $0) }
        let count = try store.remove(heartbeats, from: set)
        return count
    }
    
    public func each(_ block: (ProcessState) -> ()) throws {
        let store = SwiftkiqClient.current.store
        let processeKeys: [String] = try store.members(self).sorted { $0 < $1 }
        
        let converter = JsonConverter.default
        let pipeline = try store.pipelined()
        for processKey in processeKeys {
            try pipeline.addCommand("HMGET", params: [processKey, "info", "busy", "beat", "quit"])
        }
        
        let responses = try pipeline.execute()
        let tmp: [[String]] = responses.flatMap { try? $0.toArray() }
            .map { $0.flatMap { try? $0.toString() } }
        let filtered = tmp.filter { $0.count == 4 }
        let processes = filtered.map { (elem: [String]) -> [String: Any?] in
            let info: [String: Any] = converter.deserialize(dictionary: elem[0])
            let dict: [String: Any?] = [
                "info": info,
                "busy": Int(elem[1]),
                "beat": Double(elem[2]),
                "quit": Bool(elem[3])]
            return dict
        }
        let parsedProcesses = ProcessState.from(processes as NSArray) ?? []
        for process in parsedProcesses {
            block(process)
        }
    }
    
    public var count: Int {
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

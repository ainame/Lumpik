//
//  Api.swift
//  Swiftkiq
//
//  Created by satoshi.namai on 2017/03/06.
//
//

import Foundation
import Mapper
import Redis

public final class ProcessSet: Set {
    public convenience init() {
        self.init(rawValue: "processes")
    }
    
    @discardableResult
    public static func cleanup() throws -> Int {
        let set = ProcessSet()
        return try Application.connectionPool { conn in
            let processeKeys: [String] = try conn.members(set)
            
            guard processeKeys.count > 0 else {
                return 0
            }
            
            let pipeline = conn.pipelined()
            for processKey in processeKeys {
                try pipeline.enqueue(Command("HGET"), [processKey.makeBytes(), "info".makeBytes()])
            }
            let heartbeats = try pipeline.execute().map { $0!.string }
            
            var pruned = [String]()
            for (index, beat) in heartbeats.enumerated() {
                if beat != nil {
                    pruned.append(processeKeys[index])
                }
            }
            guard pruned.count > 0 else {
                return 0
            }
            return try conn.remove(pruned, from: set)
        }
    }
    
    public func each(_ block: (ProcessState) -> ()) throws {
        _ = try Application.connectionPool { conn in
            let processeKeys: [String] = try conn.members(self).sorted { $0 < $1 }
            
            let converter = JsonConverter.default
            let pipeline = conn.pipelined()
            for processKey in processeKeys {
                try pipeline.enqueue(Command("HMGET"), [processKey, "info", "busy", "beat", "quit"].map { $0.makeBytes() })
            }
            
            let responses = try pipeline.execute()
            let tmp: [[String]] = responses.flatMap { $0!.array!.map { $0!.string! } }
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
    }
    
    public var count: Int {
        return ((try? Application.connectionPool { try $0.size(self) }) ?? 0)
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
        _ = try Application.connectionPool { conn in
            try conn.clear(self)
        }
    }
    
    public func 💣() throws {
        try clear()
    }
}

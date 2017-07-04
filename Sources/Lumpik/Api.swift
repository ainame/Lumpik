//
//  Api.swift
//  Lumpik
//
//  Created by satoshi.namai on 2017/03/06.
//
//

import Foundation
import Redis

public final class ProcessSet: Set {
    static var connectionPool = AnyConnectablePool<RedisStore>(Application.default.connectionPool)

    public convenience init() {
        self.init(rawValue: "processes")
    }
    
    @discardableResult
    public static func cleanup() throws -> Int {
        let set = ProcessSet()
        return try connectionPool.with { conn in
            let processeKeys: [String] = try conn.members(set)
            
            guard processeKeys.count > 0 else {
                return 0
            }
            
            let pipeline = conn.pipelined()
            for processKey in processeKeys {
                try pipeline.enqueue(Command("HGET"), [processKey.makeBytes(), "info".makeBytes()])
            }
            let heartbeats = try pipeline.execute().map { $0?.string }
            
            var pruned = [String]()
            for (index, beat) in heartbeats.enumerated() where beat != nil {
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
        _ = try ProcessSet.connectionPool.with { conn in
            let processeKeys: [String] = try conn.members(self).sorted { $0 < $1 }
            let decoder = JSONDecoder()
            let pipeline = conn.pipelined()
            for processKey in processeKeys {
                try pipeline.enqueue(Command("HMGET"), [processKey, "info", "busy", "beat", "quit"].map { $0.makeBytes() })
            }
            
            let responses = try pipeline.execute()
            let filtered: [[String]] = responses.flatMap { $0 }.flatMap { $0.array!.flatMap { $0?.string } }.filter { $0.count == 4 }
            let processStates: [ProcessState] = try filtered.map { values in
                let process: Process = try decoder.decode(Lumpik.Process.self, from: values[0].data(using: .utf8)!)
                return ProcessState(info: process,
                                    busy: Int(values[1]),
                                    beat: Date(timeIntervalSince1970: Double(values[2])!),
                                    quit: Bool(values[3])!)
            }
            for process in processStates {
                block(process)
            }
        }
    }
    
    public var count: Int {
        return ((try? ProcessSet.connectionPool.with { try $0.size(self) }) ?? 0)
    }
}

public class JobSet: SortedSet {
}

public final class ScheduledSet: JobSet {
    public convenience init() {
        self.init(rawValue: "schedule")
    }
}

public final class RetrySet: JobSet {
    public convenience init() {
        self.init(rawValue: "retry")
    }
}

public final class DeadSet: JobSet {
    public static let timeout: Double = 180 * 24 * 60.0 * 60.0 // 6 months
    public static let maxJobs: Int = 10000
    
    public convenience init() {
        self.init(rawValue: "dead")
    }
}


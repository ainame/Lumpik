//
//  Heart.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/20.
//
//

import Foundation

public class Heart {
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "Y-M-d"
        return formatter
    }()
    
    let converter: Converter = JsonConverter.default

    private let concurrency: Int
    private let queues: [Queue]
    
    init(concurrency: Int, queues: [Queue]) {
        self.concurrency = concurrency
        self.queues = queues
    }
    
    func beat(done: Bool) {
        let store = SwiftkiqClient.current.store
        let workerKey = "\(ProcessIdentityGenerator.identity):workers"
        
        var processed = 0
        var failed = 0
        Processor.processedCounter.update { processed = $0; return 0 }
        Processor.failureCounter.update { failed = $0; return 0 }
        
        do {
            let nowdate = formatter.string(from: Date())
            let transaction = try store.pipelined()
                .addCommand("MULTI")
                .addCommand("INCRBY", params: ["stat:processed", "\(processed)"])
                .addCommand("INCRBY", params: ["stat:failed", "\(failed)"])
                .addCommand("INCRBY", params: ["stat:processed:\(nowdate)", "\(processed)"])
                .addCommand("INCRBY", params: ["stat:failed:\(nowdate)", "\(processed)"])
                .addCommand("DEL", params: [workerKey])
            
            for (jid, workerState) in Processor.workerStates {
                try transaction.addCommand("HSET", params: [
                    workerKey, jid.rawValue,
                    converter.serialize(workerState.work.job)])
            }
            try transaction
                .addCommand("EXPIRE", params: [workerKey, String(60)])
                .addCommand("EXEC")
                .execute()
            
            let processState = Process(
                identity: ProcessIdentityGenerator.identity,
                hostname: ProcessInfo.processInfo.hostName,
                startedAt: Date(),
                pid: Int(ProcessInfo.processInfo.processIdentifier),
                tag: "",
                concurrency: concurrency,
                queues: queues,
                labels: [""])
            
            try store.pipelined()
                .addCommand("MULTI")
                .addCommand("SADD", params: ["processes", workerKey])
                .addCommand("EXISTS", params: [workerKey])
                .addCommand("HMSET", params: [
                    workerKey,
                    "info", processState.json,
                    "busy", "\(Processor.workerStates.count)",
                    "beat", "\(Date().timeIntervalSince1970)",
                    "quit", "\(done)"])
                .addCommand("EXPIRE", params: [workerKey, "60"])
                .addCommand("RPOP", params: ["\(workerKey)-signals"])
                .addCommand("EXEC")
                .execute()
        } catch let error {
            print("heartbeat: \(error)")
            Processor.processedCounter.increment(by: processed)
            Processor.failureCounter.increment(by: failed)
        }
    }
}

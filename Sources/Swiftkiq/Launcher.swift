//
//  Launcher.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Daemon

public struct LaunchOptions {
    let concurrency: Int
    let queues: [Queue]
    let strategy: Fetcher.Type
    let router: Routable
    let daemonize: Bool

    public init(concurrency: Int = 25, queues: [Queue],
                strategy: Fetcher.Type = BasicFetcher.self,
                router: Routable,
                daemonize: Bool = false) {
        self.concurrency = concurrency
        self.queues = queues
        self.strategy = strategy
        self.router = router
        self.daemonize = daemonize
    }
}

public class Launcher {
    let options: LaunchOptions
    let manager: Manager
    let poller: Poller
    let heartbeatQueue = DispatchQueue(label: "tokyo.ainame.swiftkiq.launcher.heartbeat")
    let formatter: DateFormatter
    let converter: Converter = JsonConverter.default
    
    var done: Bool = false
    var isStopping: Bool { return done }

    required public init(options: LaunchOptions) {
        self.options = options
        self.manager = Manager(concurrency: options.concurrency,
                               queues: options.queues,
                               strategy: options.strategy,
                               router: options.router)
        self.poller = Poller()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "Y-M-d"
        self.formatter = formatter
    }

    public func run() {
        if options.daemonize {
            Daemon.daemonize()
        }
        
        self.startHeartbeat()
        self.manager.start()
        self.poller.start()
    }
    
    func startHeartbeat() {
        heartbeatQueue.async { [weak self] in
            while true {
                do {
                    try self?.heartbeat()
                } catch {
                    print("heartbeat failure: \(error)")
                }
                sleep(5)
            }
        }
    }
    
    func heartbeat() throws {
        let store = SwiftkiqClient.current.store
        let workerKey = "\(ProcessIdentityGenerator.identity):workers"
        
        var processed = 0
        var failed = 0
        Processor.processedCounter.update { processed = $0; return 0 }
        Processor.failureCounter.update { failed = $0; return 0 }
        
        do {
            let nowdate = formatter.string(from: Date())
            let transaction = try store.multi()
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
                .exec()
            
            let processState = ProcessState(
                hostname: ProcessInfo.processInfo.hostName,
                startedAt: Date(),
                pid: Int(ProcessInfo.processInfo.processIdentifier),
                tag: "",
                concurrency: options.concurrency,
                queues: options.queues,
                labels: [""],
                identity: ProcessIdentityGenerator.identity)
            
            try store.multi()
                .addCommand("SADD", params: ["processes", workerKey])
                .addCommand("EXISTS", params: [workerKey])
                .addCommand("HMSET", params: [workerKey,
                                              "info", processState.json,
                                              "busy", "\(Processor.workerStates.count)",
                    "beat", "\(Date().timeIntervalSince1970)",
                    "quit", "\(done)"])
                .addCommand("EXPIRE", params: [workerKey, "60"])
                .addCommand("RPOP", params: ["\(workerKey)-signals"])
                .exec()
        } catch let error {
            print("heartbeat: \(error)")
            Processor.processedCounter.increment(by: processed)
            Processor.failureCounter.increment(by: failed)
        }
    }
}

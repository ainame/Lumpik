//
//  Launcher.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Dispatch
import Daemon
import Signals

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
    var isStopping: Bool { return done }

    private let manager: Manager
    private let poller: Poller
    private let heart: Heart
    private let heartbeatQueue = DispatchQueue(label: "tokyo.ainame.swiftkiq.launcher.heartbeat")
    private var done: Bool = false

    required public init(options: LaunchOptions) {
        self.options = options
        self.manager = Manager(concurrency: options.concurrency,
                               queues: options.queues,
                               strategy: options.strategy,
                               router: options.router)
        self.poller = Poller()
        self.heart = Heart(concurrency: options.concurrency, queues: options.queues)
        
        if !LoggerInitializer.isInitialized {
            LoggerInitializer.initialize()
        }
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
                    logger.error("heartbeat failure: \(error)")
                }
                sleep(5)
            }
        }
    }
    
    func heartbeat() throws {
        heart.beat(done: done)
    }
}

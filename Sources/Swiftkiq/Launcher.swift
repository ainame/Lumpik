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
    let timeout: TimeInterval
    let connectionPool: Int

    public init(concurrency: Int = 25, queues: [Queue],
                strategy: Fetcher.Type = BasicFetcher.self,
                router: Routable,
                daemonize: Bool = false,
                timeout: TimeInterval = 8.0,
                connectionPool: Int = 5) {
        self.concurrency = concurrency
        self.queues = queues
        self.strategy = strategy
        self.router = router
        self.daemonize = daemonize
        self.timeout = timeout
        self.connectionPool = connectionPool
    }
}

public class Launcher {
    let options: LaunchOptions
    var isStopping: Bool { return done.value }

    private let manager: Manager
    private let poller: Poller
    private let heart: Heart
    private let heartbeatQueue = DispatchQueue(label: "tokyo.ainame.swiftkiq.launcher.heartbeat")
    private let done = AtomicProperty<Bool>(false)

    public static func makeLauncher(options: LaunchOptions) -> Launcher {
        return Launcher(options: options)
    }

    private init(options: LaunchOptions) {
        self.options = options
        self.manager = Manager(concurrency: options.concurrency,
                               queues: options.queues,
                               strategy: options.strategy,
                               router: options.router)
        self.poller = Poller()
        self.heart = Heart(concurrency: options.concurrency, queues: options.queues)
    }

    public func run() {
        if options.daemonize {
            Daemon.daemonize()
        }

        if !LoggerInitializer.isInitialized {
            LoggerInitializer.initialize()
        }


        self.startHeartbeat()
        self.manager.start()
        self.poller.start()
    }

    public func stop() {
        quiet()

        let deadline = Date().addingTimeInterval(options.timeout)
        manager.stop(deadline: deadline)

        clearHeatbeat()
    }

    public func quiet() {
        done.value = true
        manager.quiet()
        poller.terminate()
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
        heart.beat(done: done.value)
    }

    func clearHeatbeat() {
        logger.warning("TOOD: implement clearHeatbeat, but no problem currently")
    }
}

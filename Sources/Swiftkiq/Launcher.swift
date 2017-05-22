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
import Redis

public struct LaunchOptions {
    var concurrency: Int = 25
    var queues: [Queue] = [Queue("default")]
    var strategy: Fetcher.Type = BasicFetcher.self
    var daemonize: Bool = false
    var timeout: TimeInterval = 8.0
    var connectionPool: Int = 5
    var loglevel: LoggerInitializer.Loglevel = .debug
    var logfile: URL? = nil
    var pidfile: URL? = nil
    var router: Routable!
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
        
        LoggerInitializer.initialize(loglevel: options.loglevel, logfile: options.logfile)
        logger.info("start swiftkiq pid=\(ProcessInfo.processInfo.processIdentifier)")
        
        self.startHeartbeat()
        self.manager.start()
        self.poller.start()
    }

    public func stop() {
        quiet()

        let deadline = Date().addingTimeInterval(options.timeout)
        manager.stop(deadline: deadline)

        heart.clear()
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
        try heart.beat(done: done.value)
    }
}

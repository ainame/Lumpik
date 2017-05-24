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
    
    static func makeLaunchOptions(_ dictionary: [String: Any]) -> LaunchOptions {
        var launchOptions = LaunchOptions()
        
        if let concurrency = dictionary["concurrency"]  as? Int {
            launchOptions.concurrency = concurrency
        }
        
        if let connectionPool = dictionary["connectionPool"]  as? Int {
            launchOptions.connectionPool = connectionPool
        }

        if let queues = dictionary["queues"] as? [String] {
            launchOptions.queues = queues.map { Queue($0) }
        }
        
        if let pidfile = dictionary["pidfile"] as? String {
            launchOptions.pidfile = URL(fileURLWithPath: pidfile)
        }
        
        if let logfile = dictionary["logfile"] as? String {
            launchOptions.logfile = URL(fileURLWithPath: logfile)
        }

        if let loglevel = dictionary["loglevel"] as? String {
            launchOptions.loglevel = LoggerInitializer.Loglevel(rawValue: loglevel)!
        }
        
        return launchOptions
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

    public func run() throws {
        if options.daemonize {
            Daemon.daemonize()
        }
        
        LoggerInitializer.initialize(loglevel: options.loglevel, logfile: options.logfile)
        
        logger.info("start swiftkiq pid=\(ProcessInfo.processInfo.processIdentifier)")
        try writePidfile()
        
        startHeartbeat()
        manager.start()
        poller.start()
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
    
    func writePidfile() throws {
        guard let pidfile = options.pidfile else { return }
        let data = "\(ProcessInfo.processInfo.processIdentifier)".data(using: .utf8)
        FileManager.default.createFile(atPath: pidfile.path, contents: data, attributes: nil)
    }
}

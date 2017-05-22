//
//  CommandLine.swift
//  Swiftkiq
//
//  Created by satoshi.namai on 2017/03/24.
//
//

import Foundation
import Signals
import Commander

// Signals captured context as a C function
fileprivate var stopHandler: (()->())? = nil
fileprivate var quietHandler: (()->())? = nil

public struct CLI {
    private let launcher: Launcher
    
    public static func parseOptions(closure: @escaping (LaunchOptions) -> ()) {
        command(
            VariadicOption<String>("queue", ["default"], description: "queue name"),
            Option<Int>("concurrency", 25, description: "the number of threads you want"),
            Option<String>("pid", "", description: "path of the pid file"),
            Option<String>("log", "", description: "path of the log file")
        ) { queues, concurrency, pid, log in
            var launchOptions = LaunchOptions()
            launchOptions.queues = queues.map { Queue($0) }
            launchOptions.concurrency = concurrency
            
            if pid != "" {
                launchOptions.pidfile = URL(fileURLWithPath: pid)
            }

            if log != "" {
                launchOptions.logfile = URL(fileURLWithPath: log)
            }

            closure(launchOptions)
        }.run()
    }
    
    public static func start(router: Routable) {
        parseOptions { options in
            var newOptions = options
            newOptions.router = router
            makeCLI(newOptions).start()
        }
    }
    
    public static func makeCLI(_ launchOptions: LaunchOptions) -> CLI {
        Application.initialize(mode: .server, connectionPoolSize: launchOptions.connectionPool)
        LoggerInitializer.initialize(loglevel: launchOptions.loglevel, logfile: launchOptions.logfile)
        let launcher = Launcher.makeLauncher(options: launchOptions)
        return CLI(launcher: launcher)
    }
    
    private init(launcher: Launcher) {
        self.launcher = launcher
    }

    public func start() {
        guard LoggerInitializer.isInitialized else {
            LoggerInitializer.initialize()
            return start()
        }

        logger.info("start swiftkiq pid=\(ProcessInfo.processInfo.processIdentifier)")
        registerSignalHandler()
        run()
        wait()
    }

    private func run() {
        launcher.run()
    }

    private func wait() {
        RunLoop.main.run()
    }

    private func registerSignalHandler() {
        stopHandler = {
            logger.info("Shudding down...")
            self.launcher.stop()
            logger.info("Good bye!")
            exit(0)
        }

        quietHandler = {
            logger.info("No longer accepting new work...")
            self.launcher.quiet()
        }

        Signals.trap(signal: .int) { signal in
            logger.info("signal int: \(signal)")
            stopHandler?()
        }

        Signals.trap(signal: .term) { signal in
            logger.info("signal term: \(signal)")
            stopHandler?()
        }

        Signals.trap(signal: .user(Int(SIGUSR1))) { signal in
            logger.info("signal user1: \(signal)")
            quietHandler?()
        }

        Signals.trap(signal: .user(Int(SIGUSR2))) { signal in
            logger.info("signal user2: \(signal)")
            // TODO: re-open logfile
            fatalError("not implemented signal handling of USR2")
        }
    }
}

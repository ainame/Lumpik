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
    
    public static func parseOptions(base launchOptions: LaunchOptions = LaunchOptions(), closure: @escaping (LaunchOptions) -> ()) {
        command(
            VariadicOption<String>("queue", ["default"], description: "queue name"),
            Option<Int>("concurrency", 25, description: "the number of threads you want"),
            Option<String>("pidfile", "", description: "path of the pid file"),
            Option<String>("logfile", "", description: "path of the log file"),
            Flag("daemon", description: "daemonize process", default: false)
        ) { queues, concurrency, pidfile, logfile, daemon in
            var newLaunchOptions = launchOptions
            
            newLaunchOptions.queues = queues.map { Queue($0) }
            newLaunchOptions.concurrency = concurrency
            newLaunchOptions.daemonize = daemon
            
            if pidfile != "" {
                newLaunchOptions.pidfile = URL(fileURLWithPath: pidfile)
            }

            if logfile != "" {
                newLaunchOptions.logfile = URL(fileURLWithPath: logfile)
            }

            closure(newLaunchOptions)
        }.run()
    }
    
    public static func start(router: Routable, launchOptions: LaunchOptions = LaunchOptions()) {
        parseOptions(base: launchOptions) { options in
            var newOptions = options
            newOptions.router = router
            makeCLI(newOptions).start()
        }
    }
    
    public static func makeCLI(_ launchOptions: LaunchOptions) -> CLI {
        Application.initialize(mode: .server, connectionPoolSize: launchOptions.connectionPool)
        let launcher = Launcher.makeLauncher(options: launchOptions)
        return CLI(launcher: launcher)
    }
    
    private init(launcher: Launcher) {
        self.launcher = launcher
    }

    public func start() {
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

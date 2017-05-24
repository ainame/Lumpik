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
import Yams

// Signals captured context as a C function
fileprivate var stopHandler: (()->())? = nil
fileprivate var quietHandler: (()->())? = nil

public struct CLI {
    private let launcher: Launcher

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
        do {
            try launcher.run()
        } catch {
            logger.error("Can't launch - \(error)")
        }
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

extension CLI {
    private static func loadConfig(atPath path: String) -> [String: Any] {
        guard path != "" else { return [String: Any]() }

        let yamlData = FileManager.default.contents(atPath: path)
        guard yamlData != nil,
            let string = yamlData?.makeString(),
            let yaml = try? Yams.load(yaml: string) else {
                fatalError("can't load the yaml file - \(path)")
        }
        return yaml as! [String: Any]
    }

    // yaml options can override cli arguments
    public static func parseOptions(base launchOptions: LaunchOptions = LaunchOptions(), closure: @escaping (LaunchOptions) -> ()) {
        command(
            Option<String>("config", "", description: "path of the config yaml file"),
            VariadicOption<String>("queue", ["default"], description: "queue name"),
            Option<Int>("concurrency", 25, description: "the number of threads you want"),
            Option<Int>("pool", 5, description: "the number of connection pools you want"),
            Flag("daemon", description: "daemonize process", default: false),
            Option<String>("pidfile", "", description: "path of the pid file"),
            Option<String>("logfile", "", description: "path of the log file"),
            Option<String>("loglevel", "", description: "loglevel verbose, info, debug, warning, error")
        ) { config, queues, concurrency, pool, daemon, pidfile, logfile, loglevel in
            // init an options instance from cli arguments
            var cli = launchOptions

            cli.concurrency = concurrency
            cli.queues = queues.map { Queue($0) }
            cli.connectionPool = pool
            cli.daemonize = daemon
            if pidfile != "" {
                cli.pidfile = URL(fileURLWithPath: pidfile)
            }
            if logfile != "" {
                cli.logfile = URL(fileURLWithPath: logfile)
            }
            if loglevel != "" {
                cli.loglevel = LoggerInitializer.Loglevel(rawValue: loglevel)!
            }

            // load config from yaml
            let yaml = loadConfig(atPath: config)

            // just copy
            var merged = cli

            // merge yaml config into cli config
            if let yamlQueues = yaml["queue"] as? [String] {
                merged.queues = yamlQueues.map { Queue($0) }
            }
            if let yamlConcurrency = yaml["concurrency"] as? Int {
                merged.concurrency = yamlConcurrency
            }
            if let yamlConnectionPool = yaml["connectionPool"] as? Int {
                merged.connectionPool = yamlConnectionPool
            }
            if let yamlDaemonize = yaml["daemonize"] as? Bool {
                merged.daemonize = yamlDaemonize
            }
            if let yamlPidfile = yaml["pidfile"] as? String {
                merged.pidfile = URL(fileURLWithPath: yamlPidfile)
            }
            if let yamlLogfile = yaml["logfile"] as? String {
                merged.logfile = URL(fileURLWithPath: yamlLogfile)
            }
            if let yamlLoglevel = yaml["loglevel"] as? String {
                merged.loglevel = LoggerInitializer.Loglevel(rawValue: yamlLoglevel)!
            }

            closure(merged)
        }.run()
    }
}

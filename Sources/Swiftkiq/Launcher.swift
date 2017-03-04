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

    required public init(options: LaunchOptions) {
        self.options = options
        self.manager = Manager(concurrency: options.concurrency,
                               queues: options.queues,
                               strategy: options.strategy,
                               router: options.router)
    }

    public func run() {
        if options.daemonize {
            Daemon.daemonize()
        }
        
        self.manager.start()
    }
}

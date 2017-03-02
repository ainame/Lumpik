//
//  Launcher.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation

public struct LaunchOptions {
    let concurrency: Int
    let queues: [Queue]
    let strategy: Fetcher.Type?
    let router: Routable

    public init(concurrency: Int = 25, queues: [Queue],
        strategy: Fetcher.Type?, router: Routable) {
        self.concurrency = concurrency
        self.queues = queues
        self.strategy = strategy
        self.router = router
    }
}

public class Launcher {
    let manager: Manager

    required public init(options: LaunchOptions) {
        self.manager = Manager(concurrency: options.concurrency,
                               queues: options.queues,
                               strategy: options.strategy ?? BasicFetcher.self,
                               router: options.router)
    }

    public func run() {
        self.manager.start()
    }
}

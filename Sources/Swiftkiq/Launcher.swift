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
}

public class Launcher {
    let manager: Manager
    
    init(options: LaunchOptions) {
        self.manager = Manager(concurrency: options.concurrency,
                               queues: options.queues,
                               strategy: options.strategy ?? BasicFetcher.self,
                               router: options.router)
    }
    
    func run() {
        self.manager.start()
    }
}

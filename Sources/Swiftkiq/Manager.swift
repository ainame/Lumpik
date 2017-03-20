//
//  Manager.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Dispatch
import SwiftyBeaver

protocol ProcessorLifecycleDelegate: class {
    func stopped(processor: Processor)
    func died(processor: Processor, reason: String)
}

public class Manager: ProcessorLifecycleDelegate {
    enum Control: Error {
        case shutdown
    }
    
    let concurrency: Int
    let queues: [Queue]
    let strategy: Fetcher.Type
    let router: Routable

    lazy var processors: [Processor] = {
        return (1...self.concurrency).map { index in
            let fetcher = self.strategy.init(queues: self.queues)
            let dispatchQueue = DispatchQueue(label: "swiftkiq-queue\(index)")
            return Processor(fetcher: fetcher, router: self.router, dispatchQueue: dispatchQueue, delegate: self)
        }
    }()

    init(concurrency: Int = 25, queues: [Queue], strategy: Fetcher.Type = BasicFetcher.self, router: Routable) {
        self.concurrency = concurrency
        self.router = router
        self.queues = queues
        self.strategy = strategy
    }

    func start() {
        processors.forEach { processor in
            processor.start()
        }
    }

    func stop() {
        fatalError("not implemented error")
    }

    func quit() {
        fatalError("not implemented error")
    }

    func stopped(processor: Processor) {
        logger.debug("stopped: \(processor)")
    }

    func died(processor: Processor, reason: String) {
        logger.debug("died: \(processor)")
    }
}

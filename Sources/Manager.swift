//
//  Manager.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation

protocol ProcessorLifecycleDelegate {
    func stopped(processor: Processor)
    func died(processor: Processor, reason: String)
}

class Manager: ProcessorLifecycleDelegate {
    let concurrency: Int
    let processors: [Processor]
    
    init(concurrency: Int = 25, queues: [Queue],
         strategy: Fetcher.Type = BasicFetcher.self, router: Routable) {
        self.concurrency = concurrency
        self.processors = (0...concurrency).map { index in
            DispatchQueue(label: "swiftkiq-queue\(index)")
        }.map { dispatchQueue in
            let fetcher = strategy.init(queues: queues)
            return Processor(fetcher: fetcher, router: router, dispatchQueue: dispatchQueue)
        }
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
        print("stopped: \(processor)")
    }
    
    func died(processor: Processor, reason: String) {
        print("died: \(processor)")
    }
}

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
    let concurrency: Int
    let queues: [Queue]
    let strategy: Fetcher.Type
    let router: Routable
    
    private let mutex = Mutex()
    private let done = AtomicProperty<Bool>(false)

    lazy var processors: [Processor] = {
        return (1...self.concurrency).map { index in
            return Manager.makeProcessor(index: index, queues: self.queues, strategy: self.strategy,
                                         router: self.router, delegate: self)
        }
    }()

    static func makeProcessor(index: Int, queues: [Queue], strategy: Fetcher.Type, router: Routable, delegate: ProcessorLifecycleDelegate) -> Processor {
        let fetcher = strategy.init(queues: queues)
        let dispatchQueue = DispatchQueue(label: "swiftkiq-queue\(index)")
        return Processor(fetcher: fetcher, router: router, dispatchQueue: dispatchQueue, delegate: delegate)
    }
    
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

    func quiet() {
        guard done.value != true else { return }
        done.value = true
        
        logger.info("Terminating quiet workers")
        processors.forEach { $0.terminate() }
        
        // fire event quite
    }

    // hack for quicker development / testing environment #2774
    // PAUSE_TIME = STDOUT.tty? ? 0.1 : 0.5
    static private let pauseTime: UInt32 = 500
    
    func stop() {
        quiet()
        // fire event shutdown
        sleep(Manager.pauseTime)
        guard !processors.isEmpty else { return }
        
        logger.info("Pausing to allow workers to finish...")
        
        // remaining = deadline - Time.now
        // while remaining > PAUSE_TIME
        // return if @workers.empty?
        // sleep PAUSE_TIME
        // remaining = deadline - Time.now
        // end
        // return if @workers.empty?
        
        hardShutdown()
    }
    
    func hardShutdown() {
        fatalError("not implemented yet")
    }
    
    func stopped(processor: Processor) {
        logger.debug("stopped: \(processor)")
        
        mutex.synchronize {
            guard let index = processors.index(where: { $0 === processor }) else { return }
            processors.remove(at: index)
        }
    }

    func died(processor: Processor, reason: String) {
        logger.debug("died: \(processor)")
        
        mutex.synchronize {
            guard let index = processors.index(where: { $0 === processor }) else { return }
            processors.remove(at: index)
            
            if done.value != true {
                let processor = Manager.makeProcessor(index: processors.count, queues: queues,
                                                      strategy: strategy, router: router,
                                                      delegate: self)
                processors.append(processor)
            }
        }
    }
}

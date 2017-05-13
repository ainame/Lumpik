//
//  Fetcher.swift
//  Swiftkiq
//
//  Created by satoshi.namai on 2017/02/24.
//
//

import Foundation

public protocol Fetcher: class {
    init(queues: [Queue])
    func retriveWork() throws -> UnitOfWork?
    func bulkRequeue(_ jobs: [UnitOfWork]) throws
}

final class BasicFetcher: Fetcher {
    private let queues: [Queue]

    init(queues: [Queue]) {
        self.queues = queues
    }

    func retriveWork() throws -> UnitOfWork? {
        return try SwiftkiqClient.current.store.dequeue(randomSortedQueues())
    }
    
    func randomSortedQueues () -> [Queue] {
        var a = queues
        let n = a.count
        for i in 0..<n {
            let ai = a[i]
            let j = Int(Compat.random(n))
            if i != j {
                a[i] = a[j]
            }
            a[j] = ai
        }
        return a
    }
    
    func bulkRequeue(_ jobs: [UnitOfWork]) throws {
        let store = SwiftkiqClient.current.store
        let pipeline = store.pipelined()
        let encoder = JsonConverter.default
        
        jobs.forEach { job in
            let payload = encoder.serialize(job.job)
            try! pipeline.addCommand("RPUSH", params: [job.queue.key, payload])
        }
        
        try pipeline.execute()
    }
}

//
//  Fetcher.swift
//  Swiftkiq
//
//  Created by satoshi.namai on 2017/02/24.
//
//

import Foundation
import Redbird

public protocol Fetcher: class {
    init(processorId: Int, queues: [Queue])
    func retriveWork() throws -> UnitOfWork?
}

final class BasicFetcher: Fetcher {
    let processorId: Int
    private let queues: [Queue]

    init(processorId: Int, queues: [Queue]) {
        self.processorId = processorId
        self.queues = queues
    }

    func retriveWork() throws -> UnitOfWork? {
        return try SwiftkiqClient.current(processorId).store.dequeue(randomSortedQueues())
    }
    
    func randomSortedQueues () -> [Queue] {
        var a = queues
        let n = a.count
        for i in 0..<n {
            let ai = a[i]
            let j = Int(arc4random()) % n
            if i != j {
                a[i] = a[j]
            }
            a[j] = ai
        }
        return a
    }
}

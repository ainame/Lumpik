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
    init(queues: [Queue])
    func retriveWork() throws -> UnitOfWork?
}

final class BasicFetcher: Fetcher {
    private let queues: [Queue]

    init(queues: [Queue]) {
        self.queues = queues
    }

    func retriveWork() throws -> UnitOfWork? {
        return try SwiftkiqClient.current.store.dequeue(queues)
    }
}

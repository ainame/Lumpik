//
//  Fetcher.swift
//  Swiftkiq
//
//  Created by satoshi.namai on 2017/02/24.
//
//

import Foundation
import Redbird

protocol Fetcher {
    func retriveWork() throws -> UnitOfWork?
}

final class BasicFetcher: Fetcher {
    let queue: Queue
    init(queue: Queue) {
        self.queue = queue
    }
    
    func retriveWork() throws -> UnitOfWork? {
        return try Swiftkiq.store.dequeue(queue)!
    }
}

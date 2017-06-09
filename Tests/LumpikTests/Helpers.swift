//
//  Helpers.swift
//  LumpikTests
//
//  Created by Namai Satoshi on 2017/06/09.
//

import Foundation
@testable import Lumpik

// do not use with other thread
final class SingleConnectionPool: ConnectablePool {
    var redis: RedisStore
    
    init() {
        redis = try! RedisStore(host: "localhost", port: 6379)
    }
    
    func borrow() throws -> RedisStore {
        return redis
    }
    func checkin(_ connection: RedisStore) {
        //
    }
}

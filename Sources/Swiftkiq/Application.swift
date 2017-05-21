//
//  Application.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/05/15.
//
//

import Foundation

struct Application {
    static var `default`: Application!
    var connectionPool: ConnectionPool<RedisStore>!
    
    static func initialize(launchOptions: LaunchOptions) {
        guard self.default == nil else {
            fatalError("don't call Application#initialize twice")
        }
        
        self.default = Application()
        self.default.connectionPool = ConnectionPool<RedisStore>(maxCapacity: launchOptions.connectionPool)
    }
}

// MARK: connection pool
extension Application {
    static func connectionPool<T>(handler: (RedisStore) -> T) throws -> T {
        return try self.default.connectionPool.with { conn in
            handler(conn)
        }
    }
    
    static func connectionPool<T>(handler: (RedisStore) throws -> T) throws -> T {
        return try self.default.connectionPool.with { conn in
            try handler(conn)
        }
    }
}

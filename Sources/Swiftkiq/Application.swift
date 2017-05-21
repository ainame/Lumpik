//
//  Application.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/05/15.
//
//

import Foundation

struct Application {
    enum Mode {
        case server
        case client
    }
    
    static var `default`: Application!
    
    public var isServerMode: Bool { return mode == .server }
    private var mode: Mode!
    
    public private(set) var connectionPool: ConnectionPool<RedisStore>!

    
    // we have to pool size's margin for poller or heartbeat
    private static var connectionPoolSizeMargin: Int = 5
    
    static func initialize(launchOptions: LaunchOptions, mode: Mode = .client) {
        guard self.default == nil else {
            fatalError("don't call Application#initialize twice")
        }

        self.default = Application()
        self.default.mode = mode
        self.default.connectionPool = ConnectionPool<RedisStore>(
            maxCapacity: self.default.isServerMode ? (launchOptions.connectionPool + connectionPoolSizeMargin) : connectionPoolSizeMargin
        )
    }
}

// MARK: connection pool
extension Application {
    @discardableResult
    static func connectionPool<T>(handler: (RedisStore) -> T) throws -> T {
        return try self.default.connectionPool.with { conn in
            handler(conn)
        }
    }

    @discardableResult
    static func connectionPool<T>(handler: (RedisStore) throws -> T) throws -> T {
        return try self.default.connectionPool.with { conn in
            try handler(conn)
        }
    }
}

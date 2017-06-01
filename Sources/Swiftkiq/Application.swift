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
    
    static var `default` = Application()
    private static var isInitialized = false
    
    public var isServerMode: Bool { return mode == .server }
    private var mode: Mode = .client
    
    public private(set) var connectionPool = ConnectionPool<RedisStore>(maxCapacity: 0)
    public private(set) var connectionPoolForInternal = ConnectionPool<RedisStore>(maxCapacity: 0)
    
    static func initialize(mode: Mode = .client, connectionPoolSize: Int) {
        guard isInitialized != true else {
            fatalError("don't call initialize method twice")
        }
        
        defer { isInitialized = true }
        
        self.default.mode = mode
        self.default.connectionPool = ConnectionPool<RedisStore>(maxCapacity: connectionPoolSize)

        // for heartbeat/poller
        if mode == .server {
            self.default.connectionPoolForInternal = ConnectionPool<RedisStore>(maxCapacity: 2)
        }
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
    
    @discardableResult
    static func connectionPoolForInternal<T>(handler: (RedisStore) -> T) throws -> T {
        return try self.default.connectionPoolForInternal.with { conn in
            handler(conn)
        }
    }
    
    @discardableResult
    static func connectionPoolForInternal<T>(handler: (RedisStore) throws -> T) throws -> T {
        return try self.default.connectionPoolForInternal.with { conn in
            try handler(conn)
        }
    }
}

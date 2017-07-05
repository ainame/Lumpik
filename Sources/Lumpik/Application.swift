//
//  Application.swift
//  Lumpik
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
        
        // for heartbeat/poller
        if mode == .server {
            self.default.connectionPool = ConnectionPool<RedisStore>(maxCapacity: connectionPoolSize)
            self.default.connectionPoolForInternal = ConnectionPool<RedisStore>(maxCapacity: 5)
        } else {
            self.default.connectionPool = ConnectionPool<RedisStore>(maxCapacity: 5)
        }
    }
}

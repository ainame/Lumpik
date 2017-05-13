//
//  ConnectionPool.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/05/13.
//
//

import Foundation

protocol Connectable {
    static func makeConnection() throws -> Self
    func releaseConnection() throws
}

protocol ConnectablePool {
    associatedtype Connection: Connectable
    
    func borrow() throws -> Connection
    func takeback(_ connection: Connection)
    func with<T>(handler: (Connection) -> (T)) throws -> T
    func with<T>(handler: (Connection) throws -> (T)) throws -> T
}

enum ConnectablePoolError: Error {
    case timeout
}

struct RedisConnection: Connectable {
    var connection: Storable
    
    init(connection: Storable) {
        self.connection = connection
    }
    
    static func makeConnection() throws -> RedisConnection {
        return RedisConnection(connection: RedisStore.makeStore())
    }
    
    func releaseConnection() throws {
    }
}

class ConnectionPool: ConnectablePool {
    typealias Connection = RedisConnection
    
    let maxCapacity: Int
    private var pool = [Connection]()
    
    private let mutex = Mutex()
    private let semaphore: DispatchSemaphore
    
    init(maxCapactiy: Int) {
        self.maxCapacity = maxCapactiy
        self.semaphore = DispatchSemaphore(value: maxCapacity)
        var count = 0
        while count < maxCapacity {
            let conn = try! Connection.makeConnection()
            pool.append(conn)
            count += 1
        }
    }
    
    deinit {
        pool.forEach { conn in
            try? conn.releaseConnection()
        }
    }
    
    func borrow() throws -> Connection {
        let result = semaphore.wait(timeout: DispatchTime.now() + .seconds(1))
        switch result {
        case .success:
            mutex.lock()
            if let conn = pool.first {
                pool.removeFirst()
                mutex.unlock()
                return conn
            }
            fatalError("can't find connection item from pool")
        case .timedOut:
            throw ConnectablePoolError.timeout
        }
    }
    
    func takeback(_ connection: Connection) {
        mutex.synchronize {
            precondition(pool.count < maxCapacity)
            pool.append(connection)
        }
        semaphore.signal()
    }
    
    func with<T>(handler: (Connection) -> (T)) throws -> T {
        let conn = try borrow()
        defer { takeback(conn) }
        return handler(conn)
    }
    
    func with<T>(handler: (Connection) throws -> (T)) throws -> T {
        let conn = try borrow()
        defer { takeback(conn) }
        return try handler(conn)
    }
}

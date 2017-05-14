//
//  ConnectionPool.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/05/13.
//
//

import Foundation

public protocol Connectable {
    static func makeConnection() throws -> Self
    func releaseConnection() throws
}

public protocol ConnectablePool {
    associatedtype Connection: Connectable
    
    func borrow() throws -> Connection
    func checkin(_ connection: Connection)
    func with<T>(handler: (Connection) -> (T)) throws -> T
    func with<T>(handler: (Connection) throws -> (T)) throws -> T
}

enum ConnectablePoolError: Error {
    case timeout
}


public class ConnectionPool<T: Connectable>: ConnectablePool {
    public typealias Connection = T
    
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
    
    public func borrow() throws -> Connection {
        let result = semaphore.wait(timeout: DispatchTime.now() + .seconds(1))
        switch result {
        case .success:
            mutex.lock()
            defer { mutex.unlock() }
            if let conn = pool.popLast() {
                return conn
            }
            fatalError("can't find connection item from pool")
        case .timedOut:
            throw ConnectablePoolError.timeout
        }
    }
    
    public func checkin(_ connection: Connection) {
        mutex.synchronize {
            precondition(pool.count < maxCapacity)
            pool.append(connection)
        }
        semaphore.signal()
    }
    
    public func with<T>(handler: (Connection) -> (T)) throws -> T {
        let conn = try borrow()
        defer { checkin(conn) }
        return handler(conn)
    }
    
    public func with<T>(handler: (Connection) throws -> (T)) throws -> T {
        let conn = try borrow()
        defer { checkin(conn) }
        return try handler(conn)
    }
}

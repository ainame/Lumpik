//
//  ConcurrentUtils.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/18.
//
//

import Foundation
import Dispatch

final class Mutex {
    private var _lock = DispatchSemaphore(value: 1)
    
    func lock() {
        _ = _lock.wait(timeout: DispatchTime.distantFuture)
    }
    
    func unlock() {
        _lock.signal()
    }
    
    func synchronize<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
    
    func synchronize<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}

final class AtomicProperty<T> {
    private let mutex = Mutex()
    private var _value: T

    required init(_ initialValue: T) {
        _value = initialValue
    }
    
    var value: T {
        get {
            return mutex.synchronize { _value }
        }
        set {
            mutex.synchronize { _value = newValue }
        }
    }
}

final class AtomicCounter<T: SignedInteger> {
    private let mutex = Mutex()
    private var _value: T = 0

    var value: T {
        return mutex.synchronize { _value }
    }

    init(_ initialValue: T) {
        _value = initialValue
    }

    @discardableResult
    func increment(by count: T = 1) -> T {
        return mutex.synchronize {
            _value = _value + count
            return _value
        }
    }

    @discardableResult
    func update(_ block: (T) -> T) -> T {
        return mutex.synchronize {
            let newValue = block(_value)
            _value = newValue
            return newValue
        }
    }
}

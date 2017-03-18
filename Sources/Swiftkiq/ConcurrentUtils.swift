//
//  ConcurrentUtils.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/18.
//
//

import Foundation

final class Mutex {
    private let lock = NSLock()

    func synchronize<T>(_ block: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return block()
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

//
//  Retry.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/05.
//
//

import Foundation

struct Delay {
    static func next<W: Worker>(for worker: W, by count: Int) -> Int {
        return W.retryIn ?? next(by: count)
    }
    
    // exponential backoff
    static func next(by count: Int) -> Int {
        let item1: Int = Int(NSDecimalNumber(decimal: pow(Decimal(count), 4)))
        let item2: Int = 15
        let item3: Int = Int(Compat.random(30)) * (count + 1)
        return item1 + item2 + item3
    }
}

//
//  Utils.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/03/05.
//
//

import Foundation

#if os(Linux)
    import Glibc
#elseif os(macOS)
    import Darwin
#endif

// MARK: rand

struct Compat {
    static func random(_ max: Int) -> UInt32 {
        #if os(Linux)
            return UInt32(Glibc.random()) % UInt32(max + 1)
        #else
            return arc4random_uniform(UInt32(max))
        #endif
    }
}


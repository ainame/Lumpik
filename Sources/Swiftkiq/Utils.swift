//
//  Utils.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/05.
//
//

import Foundation
import Mapper

#if os(Linux)
    import Glibc
#elseif os(macOS)
    import Darwin
#endif

// MARK: rand

struct Compat {
    static func random(_ max: Int) -> UInt32 {
        #if os(Linux)
            return random() % max + 1
        #else
            return arc4random_uniform(UInt32(max))
        #endif
    }
}

// MARK: Mapper Convertibles

extension Queue: Convertible {
    public static func fromMap(_ value: Any) throws -> Queue {
        if let rawValue = value as? String {
            return Queue(rawValue)
        }
        throw MapperError.convertibleError(value: value, type: ConvertedType.self)
    }
}

extension Date: Convertible {
    public static func fromMap(_ value: Any) throws -> Date {
        if let floatValue = value as? Double {
            return Date(timeIntervalSinceReferenceDate: floatValue)
        }
        throw MapperError.convertibleError(value: value, type: Date.self)
    }
}

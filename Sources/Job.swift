//
//  Job.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation

public protocol Job {
    var `class`: AnyClass { get }
    var argument: String { get }
    var retry: Int { get }
    var queue: Queue { get }
    
    var serialized: Dictionary<String, Any> { get }
}

extension Job {
    public var serialized: Dictionary<String, Any> {
        return [
            "class": `class`,
            "argument": argument,
            "retry": retry,
            "queue": queue.rawValue
        ]
    }
}


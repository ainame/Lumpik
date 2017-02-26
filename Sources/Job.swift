//
//  Job.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation

public protocol Job {
    associatedtype W: Worker
    
    var `class`: W.Type { get }
    var argument: String { get }
    var retry: Int { get }
    var queue: Queue { get }
    
    var serialized: Dictionary<String, Any> { get }
}

extension Job {
    public var serialized: Dictionary<String, Any> {
        return [
            "class": String(describing: `class`),
            "argument": String(describing: argument),
            "retry": retry,
            "queue": queue.rawValue
        ]
    }
}


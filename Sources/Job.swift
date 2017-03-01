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
    var argument: W.Argument { get }
    var retry: Int { get }
    var queue: Queue { get }
    
    func invoke() throws
}

extension Job {
    public func invoke() throws {
        try self.`class`.init().perform(argument)
    }
}

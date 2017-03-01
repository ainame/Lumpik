//
//  Job.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation

public protocol JobType {
    associatedtype Worker: WorkerType
    
    static var `class`: Worker.Type { get }
    var jid: String { get }
    var argument: Worker.Argument { get }
    var retry: Int { get }
    var queue: Queue { get }
    
    func invokeWorker() throws
}

extension JobType {
    public func invokeWorker() throws {
        let worker = Self.`class`.init()
        worker.jid = jid
        try worker.perform(argument)
    }
}

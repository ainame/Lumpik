//
//  Store.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Redbird

public protocol ListStorable {
    func enqueue(_ job: Dictionary<String, Any>, to queue: Queue)
    func dequeue(_ queue: Queue) -> Dictionary<String, Any>?
}

final class MockStore: ListStorable {
    private var all = Dictionary<String, Array<Dictionary<String, Any>>>()
    
    public func dequeue(_ queue: Queue) -> Dictionary<String, Any>? {
        return all[queue.rawValue]?.removeFirst()
    }
    
    public func enqueue(_ job: Dictionary<String, Any>, to queue: Queue) {
        if var list = all[queue.rawValue] {
            list.append(job)
        } else {
            var list = Array<Dictionary<String, Any>>()
            list.append(job)
            all[queue.rawValue] = list
        }
    }
}

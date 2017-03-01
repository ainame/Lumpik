//
//  Processor.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/26.
//
//

import Foundation
import Dispatch

public final class Processor {
    let fetcher: Fetcher
    let dipsatchQueue: DispatchQueue
    
    var down: Bool = false
    var done: Bool = false

    init(fetcher: Fetcher, dispatchQueue: DispatchQueue) {
        self.fetcher = fetcher
        self.dipsatchQueue = dispatchQueue
    }
    
    func start () {
        dipsatchQueue.async { self.run() }
    }
    
    func run() {
        do {
            while !done {
                try processOne()
            }
        } catch Swiftkiq.Control.shutdown {
            print("shutdown")
        } catch let error {
            print("ERROR: \(error)")
        }
    }
    
    func processOne() throws {
        if let work = try fetcher.retriveWork() {
            try process(work)
        }
    }
    
    func process(_ work: UnitOfWork) throws {
    }
}

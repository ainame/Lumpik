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
    let router: Routable
    let dipsatchQueue: DispatchQueue
    weak var delegate: ProcessorLifecycleDelegate!

    var down: Bool = false
    var done: Bool = false

    init(fetcher: Fetcher,
         router: Routable,
         dispatchQueue: DispatchQueue,
         delegate: ProcessorLifecycleDelegate) {
        self.fetcher = fetcher
        self.router = router
        self.dipsatchQueue = dispatchQueue
        self.delegate = delegate
    }

    func start () {
        dipsatchQueue.async { self.run() }
    }

    func run() {
        print("run!")
        do {
            while !done {
                try processOne()
            }
        } catch Manager.Control.shutdown {
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
        try router.dispatch(work)
    }
}

//
//  Scheduler.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/04.
//
//

import Foundation

public class Poller {
    static let initalWait: UInt32 = 10

    private let dispatchQueue = DispatchQueue(label: "tokyo.ainame.swiftkiq.poller")
    private var done: Bool = false

    func start() {
        dispatchQueue.async { [weak self] in
            self?.run()
        }
    }

    func terminate() {
        done = true
    }

    func enqueue () {
    }

    private func run () {
        initialWait()

        while !done {
            enqueue()
            wait()
        }
    }

    private func wait() {
        sleep(randomPollInterval())
    }

    private func randomPollInterval() -> UInt32 {
        // poll_interval_average * rand + poll_interval_average.to_f / 2
        return 1
    }

    private func initialWait() {
        // Have all processes sleep between 5-15 seconds. 10 seconds
        // to give time for the heartbeat to register (if the poll interval is going to be calculated by the number
        // of workers), and 5 random seconds to ensure they don't all hit Redis at the same time.
        let total = Poller.initalWait + (5 * Compat.random(1))
        sleep(total)
    }
}

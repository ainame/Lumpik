//
//  Poller.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/04.
//
//

import Foundation
import Dispatch

public class Poller {
    static let initalWait: UInt32 = 10

    public let averageScheduledPollInterval: Int
    
    private let dispatchQueue = DispatchQueue(label: "tokyo.ainame.swiftkiq.poller")
    private var done: Bool = false
    private var _pollIntervalAverage: Int? = nil
    
    init(averageScheduledPollInterval: Int = 15) {
        self.averageScheduledPollInterval = averageScheduledPollInterval
    }

    func start() {
        dispatchQueue.async { [weak self] in
            self?.run()
        }
    }

    func terminate() {
        done = true
    }

    func enqueue () {
        print("poll... at \(Date().timeIntervalSince1970)")
        let client = SwiftkiqClient.current
        for jobSet in [RetrySet(), ScheduledSet()] {
            do {
                let now = Date().timeIntervalSince1970
                while let job = try client.store.range(min: .infinityNegative, max: .value(now), from: jobSet, offset: 0, count: 1).first {
                    guard let queue = job["queue"] as? String else { continue }
                    
                    if try client.store.remove(job, from: jobSet) > 0 {
                        try client.enqueue(job, to: Queue(queue))
                        print("enqueued \(jobSet): \(job["jid"])")
                    }
                }
            } catch {
                print("poller error: \(error)")
            }
        }
    }

    private func run () {
        initialWait()

        while !done {
            enqueue()
            wait()
        }
    }

    private func wait() {
        let interval = randomPollInterval()
        sleep(UInt32(interval))
    }

    // calculate interval with randomness
    private func randomPollInterval() -> Int {
        return pollIntervalAverage() * Int(Compat.random(1)) + Int(Double(pollIntervalAverage()) / 2.0)
    }
    
    private func pollIntervalAverage() -> Int {
        if let val = _pollIntervalAverage {
            return val
        }
        
        var processCount = ProcessSet().size
        if processCount == 0 {
            processCount = 1
        }
        
        let newValue = processCount * averageScheduledPollInterval
        _pollIntervalAverage = newValue
        return newValue
    }

    private func initialWait() {
        // Have all processes sleep between 5-15 seconds. 10 seconds
        // to give time for the heartbeat to register (if the poll interval is going to be calculated by the number
        // of workers), and 5 random seconds to ensure they don't all hit Redis at the same time.
        let total = Poller.initalWait + (5 * Compat.random(1))
        sleep(total)
    }
}

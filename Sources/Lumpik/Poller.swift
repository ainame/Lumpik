//
//  Poller.swift
//  Lumpik
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
    private let converter = JsonConverter.default
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

    func enqueue () throws {
        logger.debug("poll... at \(Date().timeIntervalSince1970)")
        _ = try Application.connectionPoolForInternal { conn in
            for jobSet in [RetrySet(), ScheduledSet()] {
                do {
                    let now = Date().timeIntervalSince1970
                    while let job = try conn.range(min: .infinityNegative, max: .value(now), from: jobSet, offset: 0, count: 1).first {
                        guard let queue = job["queue"] as? String else { continue }
                        let serialized = try converter.serialize(job)
                        if try conn.remove([serialized], from: jobSet) > 0 {
                            try LumpikClient.enqueue(job, to: Queue(queue))
                            logger.error("enqueued \(jobSet): \(String(describing: job["jid"]))")
                        }
                    }
                } catch {
                    logger.error("poller error: \(error)")
                }
            }
        }
    }

    private func run () {
        initialWait()

        while !done {
            try? enqueue()
            wait()
        }
    }

    private func wait() {
        do {
            let interval = try randomPollInterval()
            sleep(UInt32(interval))
        } catch {
            logger.error(error)
            sleep(UInt32(averageScheduledPollInterval))
        }
    }

    // calculate interval with randomness
    private func randomPollInterval() throws -> Int {
        return try pollIntervalAverage() * Int(Compat.random(1)) + Int(Double(pollIntervalAverage()) / 2.0)
    }

    private func pollIntervalAverage() throws -> Int {
        if let val = _pollIntervalAverage {
            return val
        }

        var processCount = try ProcessSet().count()
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

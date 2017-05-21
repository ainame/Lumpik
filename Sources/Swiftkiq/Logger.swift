//
//  Logger.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/21.
//
//

import Foundation
import SwiftyBeaver

let logger = SwiftyBeaver.self

public struct LoggerInitializer {
    public enum Loglevel: Int {
        case verbose = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4

        fileprivate var converted: SwiftyBeaver.Level {
            return SwiftyBeaver.Level(rawValue: self.rawValue)!
        }
    }

    public static private(set) var isInitialized: Bool = false

    // format sample
    // [2017-05-21 17:24:20.393]   INFO: jid=eb490cea-bebd-485e-9b31-6c21d3039190 EchoWorker start
    public static var format = "[$DYYYY-MM-dd HH:mm:ss.SSS$d]$L: $M"

    public static func initialize(loglevel: Loglevel = .debug) {
        guard isInitialized == false else {
            logger.warning("already initialized logger")
            return
        }

        let dest = ConsoleDestination()
        dest.minLevel = loglevel.converted
        dest.format = self.format
        dest.levelString.verbose  = "VERBOSE"
        dest.levelString.debug    = "  DEBUG"
        dest.levelString.info     = "   INFO"
        dest.levelString.warning  = "   WARN"
        dest.levelString.error    = "  ERROR"

        logger.addDestination(dest)

        isInitialized = true
    }
}

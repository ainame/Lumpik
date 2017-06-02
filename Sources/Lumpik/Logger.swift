//
//  Logger.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/03/21.
//
//

import Foundation
import SwiftyBeaver

public let logger = SwiftyBeaver.self

public struct LoggerInitializer {
    public enum Loglevel: String {
        case verbose
        case debug
        case info
        case warning
        case error

        fileprivate var converted: SwiftyBeaver.Level {
            return SwiftyBeaver.Level(rawValue: self.number)!
        }
        
        var number: Int {
            switch self {
            case .verbose:
                return 0
            case .debug:
                return 1
            case .info:
                return 2
            case .warning:
                return 3
            case .error:
                return 4
            }
        }
    }

    public static private(set) var isInitialized: Bool = false

    // format sample
    // [2017-05-21 17:24:20.393]   INFO: jid=eb490cea-bebd-485e-9b31-6c21d3039190 EchoWorker start
    public static var format = "[$DYYYY-MM-dd HH:mm:ss.SSS$d]$L: $M"

    public static func initialize(loglevel: Loglevel = .debug, logfile: URL? = nil) {
        defer { isInitialized = true }
        guard isInitialized == false else {
            logger.warning("already initialized logger")
            return
        }

        if let url = logfile {
            let file = FileDestination()
            file.logFileURL = url
            logger.addDestination(configureDestination(file, loglevel))
        } else {
            logger.addDestination(configureDestination(ConsoleDestination(), loglevel))
        }
    }

    private static func configureDestination<T: BaseDestination>(_ dest: T, _ loglevel: Loglevel) -> T {
        dest.minLevel = loglevel.converted
        dest.format = self.format
        dest.levelString.verbose  = "VERBOSE"
        dest.levelString.debug    = "  DEBUG"
        dest.levelString.info     = "   INFO"
        dest.levelString.warning  = "   WARN"
        dest.levelString.error    = "  ERROR"
        return dest
    }
}

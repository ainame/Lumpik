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
    public static var format = "$DHH:mm:ss.SSS$d $C[$L]$c: $M - $N.$F:$l"
    
    public static func initialize(loglevel: Loglevel = .debug) {
        guard isInitialized == false else {
            logger.warning("already initialized logger")
            return
        }
        
        let dest = ConsoleDestination()
        dest.minLevel = loglevel.converted
        dest.format = self.format
        logger.addDestination(dest)
        
        isInitialized = true
    }
}

//
//  CommandLine.swift
//  Swiftkiq
//
//  Created by satoshi.namai on 2017/03/24.
//
//

import Foundation
import Signals

// Signals captured context as a C function
fileprivate var stopHandler: (()->())? = nil
fileprivate var quietHandler: (()->())? = nil

public struct CLI {
    private let launcher: Launcher
    
    public init(launcher: Launcher) {
        self.launcher = launcher
    }
    
    public func start() {
        guard LoggerInitializer.isInitialized else {
            LoggerInitializer.initialize()
            return start()
        }
        
        logger.info("start swiftkiq pid=\(ProcessInfo.processInfo.processIdentifier)")
        registerSignalHandler()
        run()
        wait()
    }
    
    private func run() {
        launcher.run()
    }
    
    private func wait() {
        RunLoop.main.run()
    }
    
    private func registerSignalHandler() {
        stopHandler = {
            logger.info("Shudding down...")
            self.launcher.stop()
            logger.info("Good bye!")
            exit(0)
        }
        
        quietHandler = {
            logger.info("No longer accepting new work...")
            self.launcher.quiet()
        }
        
        Signals.trap(signal: .int) { signal in
            logger.info("signal int: \(signal)")
            stopHandler?()
        }
        
        Signals.trap(signal: .term) { signal in
            logger.info("signal term: \(signal)")
            stopHandler?()
        }
        
        Signals.trap(signal: .user(Int(SIGUSR1))) { signal in
            logger.info("signal user1: \(signal)")
            quietHandler?()
        }
        
        Signals.trap(signal: .user(Int(SIGUSR2))) { signal in
            logger.info("signal user2: \(signal)")
            // TODO: re-open logfile
            fatalError("not implemented signal handling of USR2")
        }
    }
}

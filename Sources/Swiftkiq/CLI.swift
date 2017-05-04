//
//  CommandLine.swift
//  Swiftkiq
//
//  Created by satoshi.namai on 2017/03/24.
//
//

import Foundation
import Signals

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
        Signals.trap(signal: .int) { signal in
            print("signal int: \(signal)")
            exit(1)
        }
        
        Signals.trap(signal: .term) { signal in
            print("signal term: \(signal)")
            exit(1)
        }
        
        Signals.trap(signal: .user(1)) { signal in
            print("signal user1: \(signal)")
            exit(1)
        }
        
        Signals.trap(signal: .user(2)) { signal in
            print("signal user2: \(signal)")
            exit(1)
        }
        
        Signals.trap(signal: .user(3)) { signal in
            print("signal user3: \(signal)")
            exit(1)
        }
    }
}

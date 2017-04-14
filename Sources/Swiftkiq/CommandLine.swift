//
//  CommandLine.swift
//  Swiftkiq
//
//  Created by satoshi.namai on 2017/03/24.
//
//

import Foundation
import Signals

struct CommandLine {
    let launcher: Launcher
    init(options: LaunchOptions) {
        self.launcher = Launcher(options: options)

    }

    func registerSignalHandler() {
        Signals.trap(signal: .int) { signal in
            print("signal int: \(signal)")
        }

        Signals.trap(signal: .term) { signal in
            print("signal int: \(signal)")
        }

        Signals.trap(signal: .user(1)) { signal in
            print("signal int: \(signal)")
        }

        Signals.trap(signal: .user(2)) { signal in
            print("signal int: \(signal)")
        }

        Signals.trap(signal: .user(3)) { signal in
            print("signal int: \(signal)")
        }

        Signals.trap(signal: .term) { signal in
            print("signal int: \(signal)")
        }
    }
}

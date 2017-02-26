//
//  Fetcher.swift
//  Swiftkiq
//
//  Created by satoshi.namai on 2017/02/24.
//
//

import Foundation
import Redbird

class Fetcher {
    let redis: Redbird

    init(redis: Redbird) {
        self.redis = redis
    }
}

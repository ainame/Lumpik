//
//  JsonHelper.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/27.
//
//

import Foundation
import SwiftRedis

struct JsonHelper {
    static let defaultWriteOption = JSONSerialization.WritingOptions()
    static let defaultReadOption = JSONSerialization.ReadingOptions()
    
    static func serialize(_ dictionary: Dictionary<String, Any>) -> String {
        let data = try! JSONSerialization.data(withJSONObject: dictionary, options: JsonHelper.defaultWriteOption)
        return String(bytes: data, encoding: .utf8)!
    }
    
    static func deserialize(_ response: [RedisString?]) -> Dictionary<String, Any> {
        guard let value = response[1] else { fatalError("can't parse response") }
        let data = value.asString.data(using: .utf8)!
        let json = try! JSONSerialization.jsonObject(with: data, options: JsonHelper.defaultReadOption)
        return json as! Dictionary<String, Any>
    }
}

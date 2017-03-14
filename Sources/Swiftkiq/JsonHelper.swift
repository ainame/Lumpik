//
//  JsonHelper.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/27.
//
//

import Foundation

struct JsonHelper {
    static let defaultWriteOption = JSONSerialization.WritingOptions()
    static let defaultReadOption = JSONSerialization.ReadingOptions()
    
    static func serialize(_ dictionary: Dictionary<String, Any>) -> String {
        let data = try! JSONSerialization.data(withJSONObject: dictionary, options: JsonHelper.defaultWriteOption)
        return String(bytes: data, encoding: .utf8)!
    }
    
    static func deserialize(_ jsonString: String) -> Dictionary<String, Any> {
        let data = jsonString.data(using: .utf8)!
        let json = try! JSONSerialization.jsonObject(with: data, options: JsonHelper.defaultReadOption)
        return json as! Dictionary<String, Any>
    }
}

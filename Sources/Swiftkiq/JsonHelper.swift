//
//  JsonHelper.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/27.
//
//

import Foundation
import Redbird

struct JsonHelper {
    static let defaultWriteOption = JSONSerialization.WritingOptions()
    static let defaultReadOption = JSONSerialization.ReadingOptions()
    
    func serialize(_ dictionary: Dictionary<String, Any>) -> String {
        let data = try! JSONSerialization.data(withJSONObject: dictionary, options: JsonHelper.defaultWriteOption)
        return String(bytes: data, encoding: .utf8)!
    }

    func deserialize(_ response: RespObject) -> Dictionary<String, Any> {
        let array = try! response.toArray()
        let data = try! array[1].toString().data(using: .utf8)!
        let json = try! JSONSerialization.jsonObject(with: data, options: JsonHelper.defaultReadOption)
        return json as! Dictionary<String, Any>
    }
}

//
//  JsonHelper.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/02/27.
//
//

import Foundation
import Redbird
import Jay

struct JsonHelper {
    let jay = Jay()
    
    func serialize(_ dictionary: Dictionary<String, Any>) -> String {
        let json = try! jay.dataFromJson(anyDictionary: dictionary)
        return String(bytes: json, encoding: .utf8)!
    }
    
    func deserialize(_ response: RespObject) -> Dictionary<String, Any> {
        let array = try! response.toArray()
        let string = try! array[1].toMaybeString()!.utf8
        let json = try! jay.anyJsonFromData(Array<UInt8>(string))
        
        return json as! Dictionary<String, Any>
    }
}

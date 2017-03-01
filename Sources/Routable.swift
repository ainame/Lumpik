//
//  Routable.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/02.
//
//

import Foundation

protocol Routable {
    func dispatch<J: Job>(className: String) -> J
}

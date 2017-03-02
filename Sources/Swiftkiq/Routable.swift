//
//  Routable.swift
//  Swiftkiq
//
//  Created by Namai Satoshi on 2017/03/02.
//
//

import Foundation

public protocol Routable {
    func dispatch(_ work: UnitOfWork) throws
}

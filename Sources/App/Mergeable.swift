//
//  Mergeable.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 8/27/21.
//

import Foundation

protocol Mergeable: Collection {
	
	mutating func merge(with: Self)
	
}

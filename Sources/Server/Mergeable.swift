//
//  Mergeable.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 8/27/21.
//

import Foundation

/// Collections that conform to this protocol can be merged with a single invocation of `merge(with:)`.
protocol Mergeable: Collection {
	
	mutating func merge(with: Self)
	
}

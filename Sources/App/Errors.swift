//
//  Errors.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 2/22/22.
//

import Foundation

enum NetworkError: LocalizedError {
	
	case invalidResponseEncoding
	
	case unknown
	
	var errorDescription: String? {
		get {
			switch self {
			case .invalidResponseEncoding:
				return "The encoding of the response is invalid."
			case .unknown:
				return "An unknown network error occurred."
			}
		}
	}
	
}

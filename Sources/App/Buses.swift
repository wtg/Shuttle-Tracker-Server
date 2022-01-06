//
//  Buses.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 10/16/21.
//

import Foundation
import JSONParser

/// A representation of all of the known buses.
/// - Warning: Don’t create instances this class yourself; instead use the shared instance.
class Buses: JSONProvider {
	
	/// A mapping of backend bus IDs to frontend bus IDs.
	class BusIDMap: JSONProvider {
		
		/// The internal JSON parser.
		/// - Warning: Don’t access this property directly.
		let parser: DictionaryJSONParser?
		
		/// Creates a mapping of backend bus IDs to frontend bus IDs.
		/// - Warning: Don’t call this initializer yourself; instead use the `busIDMap` property on the shared `Buses` instance.
		/// - Parameter parser: A JSON parser that contains the mapping data.
		fileprivate init(parser: DictionaryJSONParser) {
			self.parser = parser
		}
		
		/// Gets the frontend bus ID that’s associated with the specified backend bus ID.
		subscript(_ backendID: String) -> Int? {
			return self[backendID, as: Int.self]
		}
		
	}
	
	/// The shared instance.
	static let sharedInstance = Buses()
	
	/// A set of the IDs of all of the known buses.
	let allBusIDs: Set<Int>
	
	/// A mapping of backend IDs to frontent IDs.
	let busIDMap: BusIDMap
	
	/// The internal JSON parser.
	/// - Warning: Don’t access this property directly.
	let parser: DictionaryJSONParser?
	
	/// Creates a representation of all of the known buses.
	/// - Warning: Don’t call this initializer yourself; instead use the shared instance.
	private init() {
		let busesFileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
			.appendingPathComponent("Public", isDirectory: true)
			.appendingPathComponent("buses.json", isDirectory: false)
		let data = try! Data(contentsOf: busesFileURL)
		self.parser = data.dictionaryParser!
		self.allBusIDs = Set(data.dictionaryParser!["all", as: [Int].self]!)
		self.busIDMap = BusIDMap(parser: (data.dictionaryParser?[dictionaryAt: "map"])!)
	}
	
}

//
//  Bus.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import Fluent
import JSONParser
import Turf
import Vapor

/// A representation of a shuttle bus.
final class Bus: Hashable, Model {
	
	/// A representation of a single location datum.
	final class Location: Equatable, Content, Fields {
		
		enum LocationType: String, Codable {
			
			case system = "system"
			
			case user = "user"
			
		}
		
		/// An identifier that’s used to update location data dynamically.
		/// - Important: Location reports from the same user during the same trip should all have the same ID value.
		@ID(custom: "id", generatedBy: .user) var id: UUID?
		
		/// A timestamp that indicates when this location datum was originally collected.
		@Field(key: "date") var date: Date
		
		/// The geospatial coordinate that’s associated with this location datum.
		@Field(key: "coordinate") var coordinate: Coordinate

		/// The type of location datum, which indicates how it was originally collected.
		@Enum(key: "type") var type: LocationType
		
		init() { }
		
		/// Create a location datum.
		/// - Parameters:
		///   - id: An identifier that’s used to update location data dynamically.
		///   - date: A timestamp that indicates when the location datum was originally collected.
		///   - coordinate: The geospatial coordinate that’s associated with the location datum.
		///   - type: The type of location datum, which indicates how it was originally collected.
		/// - Important: Location reports from the same user during the same trip should all have the same ID value.
		init(id: UUID, date: Date, coordinate: Coordinate, type: LocationType) {
			self.id = id
			self.date = date
			self.coordinate = coordinate
			self.type = type
		}
		
		static func == (_ leftLocation: Bus.Location, _ rightLocation: Bus.Location) -> Bool {
			return leftLocation.id == rightLocation.id
		}
		
	}
	
	/// A simplified representation of a `Bus` instance that’s suitable to return as a response to incoming requests.
	struct Resolved: Content {
		
		/// The physical bus’s unique identifier.
		var id: Int
		
		/// The current resolved location of the physical bus.
		var location: Bus.Location
		
		/// The route along which the bus is currently traveling.
		var routeID: UUID?
		
	}
	
	static let schema = "buses"
	
	/// A simplified representation of this bus that’s suitable to return as a response to incoming requests.
	var resolved: Resolved? {
		get {
			guard let id = self.id else {
				return nil
			}
			guard let location = self.locations.resolved else {
				return nil
			}
			return Resolved(id: id, location: location, routeID: self.routeID)
		}
	}
	
	/// The physical bus’s unique identifier.
	@ID(custom: "id", generatedBy: .user) var id: Int?
	
	/// The location data for this bus.
	@Field(key: "locations") var locations: [Location]
	
	/// The congestion data for this bus.
	@OptionalField(key: "congestion") var congestion: Int?
	
	/// The distance in meters which this bus has traveled along its current route
	@OptionalField(key: "meters_traveled") var metersTraveled: Double?

	/// The ID of route along which this bus is currently traveling.
	@OptionalField(key: "route_id") var routeID: UUID?
	
	init() { }
	
	/// Creates a bus object.
	/// - Parameters:
	///   - id: The physical bus’s unique identifier.
	///   - locations: The location data for the bus.
	init(id: Int, locations: [Location] = []) {
		self.id = id
		self.locations = locations
	}
	
	static func == (_ leftBus: Bus, _ rightBus: Bus) -> Bool {
		return leftBus.id == rightBus.id
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}
	
	/// Detect the route along which this bus is currently traveling.
	func detectRoute(selectingFrom routes: [Route]) {
		guard let location = self.locations.resolved else {
			self.routeID = nil
			return
		}
		var selectedRoute: Route?
		for route in routes {
			if route.checkIsOnRoute(location: location) {
				guard selectedRoute == nil else {
					return // Since the bus is currently in an overlapping portion of multiple routes, leave the existing route association as-is
				}
				selectedRoute = route
			}
		}
		self.routeID = selectedRoute?.id
	}

	/// Detect the distance traveled along the route which this bus is currently traveling
	func detectDistanceTraveled(along routes: [Route]) {
		guard let routeID = self.routeID else {
			self.metersTraveled = 0.0
			return
		}
		// Note: There is implied coupling that if routeID is not nil then there must also be assigned location data for this bus

		// find cumulative poly-line distance from the starting waypoint to the nearest passed waypoint along the assigned route + the distance the bus has traveled from the nearest passed waypoint to its current location
		var lastDelta: Double = Double.infinity
		for route in routes {
			// detect the assigned route for this bus
			if (routeID == route.id) {
				let metersTraveled = 0
				for (index, coordinate) in route.coordinates.enumerated() {
					if (index == 0) {
						let latitudeDelta = coordinate.latitude - route.locations.last.latitude
						let longitudeDelta = coordinate.longitude - route.locations.last.longitude
						lastDelta = (pow(latitudeDelta, 2) + pow(longitudeDelta, 2)).squareRoot()
						continue
					}
					// TODO: continuously sum distance traveled here

					// TODO: find the nearest passed waypoint
					// TODO: sum the distance traveled from waypoint to waypoint only until the nearest passed waypoint
				}
				// TODO: sum the distance traveled with the distance from the nearest passed waypoint to the current bus location
			}
		}
	}
}

extension Collection where Element == Bus.Location {
	
	/// The resolved location datum from the bus’s GPS hardware.
	var systemLocation: Bus.Location? {
		get {
			return self.reversed().first { (location) -> Bool in
				return location.type == .system
			}
		}
	}
	
	/// The resolved location datum from user reports.
	var userLocation: Bus.Location? {
		get {
			let userLocations = self.filter { (location) -> Bool in
				return location.type == .user
			}
			guard userLocations.count > 0 else {
				return nil
			}
			let newestLocation = userLocations.max { (firstLocation, secondLocation) -> Bool in
				return firstLocation.date.compare(secondLocation.date) == .orderedAscending
			}
			let zeroCoordinate = Coordinate(latitude: 0, longitude: 0)
			var coordinate = userLocations.reduce(into: zeroCoordinate) { (coordinate, location) in
				coordinate += location.coordinate
			}
			coordinate /= Double(userLocations.count)
			guard let userCoordinate = coordinate == zeroCoordinate ? nil : coordinate else {
				return nil
			}
			return Bus.Location(
				id: UUID(),
				date: newestLocation?.date ?? Date(),
				coordinate: userCoordinate,
				type: .user
			)
		}
	}
	
	/// The final resolved location datum, which may or may not incorporate user-reported data.
	var resolved: Bus.Location? {
		get {
			return self.userLocation ?? self.systemLocation
		}
	}
	
}

extension Array: Mergeable where Element == Bus.Location {
	
	/// Merge other location data into this array.
	/// - Parameter otherLocations: The other location data to merge into this array.
	/// - Remark: This method implements a requirement in the `Mergeable` protocol.
	mutating func merge(with otherLocations: [Bus.Location]) {
		for otherLocation in otherLocations {
			self.removeAll { (location) in
				return location == otherLocation
			}
			self.append(otherLocation)
		}
	}
	
}


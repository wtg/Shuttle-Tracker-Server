//
//  Utilities.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 8/27/21.
//

import CoreGPX
import Fluent
import Turf
import Vapor

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif // canImport(FoundationNetworking)

public typealias Coordinate = LocationCoordinate2D

extension Coordinate: Codable, AdditiveArithmetic {
	
	enum CodingKeys: CodingKey {
		
		case latitude, longitude
		
	}
	
	public static let zero = Coordinate(latitude: 0, longitude: 0)
	
	/// Creates a coordinate representation from a GPX waypoint.
	///
	/// This initializer fails and returns `nil` if the provided GPX waypoint doesn’t contain sufficient information to create a coordinate representation.
	/// - Parameter gpxWaypoint: The GPX waypoint from which to create a coordinate representation.
	init?(from gpxWaypoint: any GPXWaypointProtocol) {
		guard let latitude = gpxWaypoint.latitude, let longitude = gpxWaypoint.longitude else {
			return nil
		}
		self.init(latitude: latitude, longitude: longitude)
	}
	
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let latitude = try container.decode(Double.self, forKey: .latitude)
		let longitude = try container.decode(Double.self, forKey: .longitude)
		self.init(latitude: latitude, longitude: longitude)
	}
	
	public static func + (lhs: Coordinate, rhs: Coordinate) -> Coordinate {
		return Coordinate(
			latitude: lhs.latitude + rhs.latitude,
			longitude: lhs.longitude + rhs.longitude
		)
	}
	
	public static func - (lhs: Coordinate, rhs: Coordinate) -> Coordinate {
		return Coordinate(
			latitude: lhs.latitude - rhs.latitude,
			longitude: lhs.longitude - rhs.longitude
		)
	}
	
	/// Numerically divides the left coordinate’s latitude and longitude values by a common divisor.
	static func / (lhs: Coordinate, rhs: Double) -> Coordinate {
		return Coordinate(
			latitude: lhs.latitude / rhs,
			longitude: lhs.longitude / rhs
		)
	}
	
	/// Numerically divides the left coordinate’s latitude and longitude values by a common divisor in-place.
	static func /= (lhs: inout Coordinate, rhs: Double) {
		lhs.latitude /= rhs
		lhs.longitude /= rhs
	}
	
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.latitude, forKey: .latitude)
		try container.encode(self.longitude, forKey: .longitude)
	}
	

}

extension LineString {
	/// Return the 1st closestVertex in the linestring. 
	/// Note that the first duplicate is returned if there are duplicate coordinates in the linestring
	func closestVertex(to coordinate: LocationCoordinate2D) -> LocationCoordinate2D? {		
		guard coordinates.count > 0 else {
				return nil
		}
		
		var closestCoordinate: LocationCoordinate2D?
		var maxDistance: LocationDistance = Double.infinity

		for index in 0..<coordinates.count - 1 {
				let distance = coordinate.distance(to: coordinates[index])
				if distance < maxDistance {
						closestCoordinate = coordinates[index]
						maxDistance = distance
				}
		}
		return closestCoordinate
	}
	func find(vertex coordinate: LocationCoordinate2D) -> Int? {
		guard coordinates.count > 0 else {
			return nil
		}
		/// Find the first occurrence of the coordinate
		for index in 0..<coordinates.count - 1 {
			if (coordinate == coordinates[index] ){
				return index
			}
		}
		return nil
	}
}

extension Array where Element: Equatable {
	
	func removingDuplicates(_ comparator: (Element, Element) throws -> Bool = (==)) rethrows -> Self {
		var newArray: Self = []
		for element in self {
			let doesContainElement = try newArray.contains { (otherElement) in
				return try comparator(element, otherElement)
			}
			if !doesContainElement {
				newArray.append(element)
			}
		}
		return newArray
	}
	
}

enum Constants {
	
	/// The current version number for the API.
	///
	/// - Remark: Increment this value every time a breaking change is made to the public-facing API.
	static let apiVersion: UInt = 3
	
	static let datafeedURL: URL = {
		if let itrakString = ProcessInfo.processInfo.environment["ITRAK"] {
			return URL(string: itrakString)!
		} else {
			return URL(string: "https://shuttletracker.app/datafeed")!
		}
	}()
	
	/// The maximum perpendicular distance, in meters, away from a route at which a coordinate is considered to be “on” that route.
	static let isOnRouteThreshold: Double = 100
	
}

enum CryptographyUtilities {
	
	static func verify(signature signatureData: Data, of contentData: Data) throws -> Bool {
		guard let keysDirectoryPath = ProcessInfo.processInfo.environment["KEYS_DIRECTORY"] else {
			throw Abort(.internalServerError)
		}
		let keyFilePaths = try FileManager.default.contentsOfDirectory(atPath: keysDirectoryPath)
			.filter { (filePath) in
				return filePath.hasSuffix(".pem")
			}
		let keysDirectoryURL = URL(fileURLWithPath: keysDirectoryPath, isDirectory: true)
		for keyFilePath in keyFilePaths {
			let keyFileURL = keysDirectoryURL.appendingPathComponent(keyFilePath)
			let publicKey: P256.Signing.PublicKey
			let signature: P256.Signing.ECDSASignature
			do {
				let keyFileContents = try String(contentsOfFile: keyFileURL.path)
				publicKey = try P256.Signing.PublicKey(pemRepresentation: keyFileContents)
				signature = try P256.Signing.ECDSASignature(rawRepresentation: signatureData)
			} catch {
				continue
			}
			if publicKey.isValidSignature(signature, for: contentData) {
				return true
			}
		}
		return false
	}
	
}

enum DateUtilities { }

extension Optional: Content, RequestDecodable, ResponseEncodable, AsyncRequestDecodable, AsyncResponseEncodable where Wrapped: Codable { }

extension Set: Content, RequestDecodable, ResponseEncodable, AsyncRequestDecodable, AsyncResponseEncodable where Element: Codable { }

extension Collection where Element: Model {
	
	/// Saves each model object in this collection.
	/// - Parameter database: The database on which to save the model objects.
	func save(on database: any Database) async throws {
		for object in self {
			try await object.save(on: database)
		}
	}
	
}

extension FILE: TextOutputStream {
	
	public mutating func write(_ string: String) {
		fputs(string, &self)
	}
	
}

extension UnsafeMutablePointer: TextOutputStream where Pointee: TextOutputStream {
	
	public func write(_ string: String) {
		self.pointee.write(string)
	}
	
}

func errorPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
	for item in items {
		print(item, terminator: separator, to: &stderr)
	}
	print(terminator, terminator: "", to: &stderr)
}

// MARK: - Compatibility shims for Linux and Windows

protocol DateIntervalProtocol {
	
	var start: Date { get }
	
	var end: Date { get }
	
	func contains(_ date: Date) -> Bool
	
}

extension DateInterval: DateIntervalProtocol { }

extension DateUtilities {
	
	/// Creates a date interval with an opaque concrete implementation.
	///
	/// The standard `DateInterval` structure from `Foundation` is partially broken on Linux and Windows, so this method will automatically select an appropriate concrete implementation that works properly on the target platform.
	/// - Parameters:
	///   - start: The start date.
	///   - end: The end date.
	/// - Returns: A value of some opaque type that conforms to `DateIntervalProtocol`.
	static func createInterval(from start: Date, to end: Date) -> some DateIntervalProtocol {
		#if os(Linux) || os(Windows)
		return CompatibilityDateInterval(start: start, end: end)
		#else // os(Linux) || os(Windows)
		return DateInterval(start: start, end: end)
		#endif
	}
	
}

#if os(Linux) || os(Windows)
extension Date {
	
	static var now: Date {
		get {
			return Date()
		}
	}
	
}

fileprivate struct CompatibilityDateInterval: DateIntervalProtocol {
	
	let start: Date
	
	let end: Date
	
	init(start: Date, end: Date) {
		self.start = start
		self.end = end
	}
	
	func contains(_ date: Date) -> Bool {
		return date >= self.start && date <= self.end
	}
	
}
#endif // os(Linux) || os(Windows)

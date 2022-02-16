//
//  Utilities.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 8/27/21.
//

import Vapor
import Fluent
import CoreGPX
import Turf
import URLSessionBackport

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif // canImport(FoundationNetworking)

typealias Coordinate = LocationCoordinate2D

extension Coordinate: Codable {
	
	enum CodingKeys: CodingKey {
		
		case latitude, longitude
		
	}
	
	/// Creates a coordinate representation from a GPX waypoint.
	///
	/// This initializer fails and returns `nil` if the provided GPX waypoint doesn’t contain sufficient information to create a coordinate representation.
	/// - Parameter gpxWaypoint: The GPX waypoint from which to create a coordinate representation.
	init?(from gpxWaypoint: GPXWaypointProtocol) {
		guard let latitude = gpxWaypoint.latitude, let longitude = gpxWaypoint.longitude else {
			return nil
		}
		self.init(latitude: latitude, longitude: longitude)
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let latitude = try container.decode(Double.self, forKey: .latitude)
		let longitude = try container.decode(Double.self, forKey: .longitude)
		self.init(latitude: latitude, longitude: longitude)
	}
	
	/// Numerically divides the right coordinate’s latitude and longitude values to the left coordinate’s respective values in place.
	static func += (_ lhs: inout Coordinate, _ rhs: Coordinate) {
		lhs.latitude += rhs.latitude
		lhs.longitude += rhs.longitude
	}
	
	/// Numerically divides the left coordinate’s latitude and longitude values by the right coordinate’s respective values in place.
	static func /= (_ lhs: inout Coordinate, _ rhs: Double) {
		lhs.latitude /= rhs
		lhs.longitude /= rhs
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.latitude, forKey: .latitude)
		try container.encode(self.longitude, forKey: .longitude)
	}
	
}

enum Constants {
	
	/// The current version number for the API.
	///
	/// Increment this value every time a breaking change is made to the public-facing API.
	static let apiVersion: UInt = 1
	
	static let datafeedURL: URL = {
		if let itrakString = ProcessInfo.processInfo.environment["ITRAK"] {
			return URL(string: itrakString)!
		} else {
			return URL(string: "https://shuttletracker.app/datafeed")!
		}
	}()
	
	/// The maximum perpendicular distance, in meters, away from a route at which a coordinate is considered to be “on” that route.
	static let isOnRouteThreshold: Double = 5
	
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

extension Optional: Content, RequestDecodable, ResponseEncodable, AsyncRequestDecodable, AsyncResponseEncodable where Wrapped: Codable { }

extension Set: Content, RequestDecodable, ResponseEncodable, AsyncRequestDecodable, AsyncResponseEncodable where Element: Codable { }

extension Collection where Element: Model {
	
	/// Saves each model object in this collection.
	/// - Parameter database: The database on which to save the model objects.
	func save(on database: Database) async throws {
		for object in self {
			try await object.save(on: database)
		}
	}
	
}

// MARK: Compatibility shims for Linux and Windows

#if os(Linux) || os(Windows)
extension Date {
	
	static var now: Date {
		get {
			return Date()
		}
	}
	
}

extension URL {
	
	typealias AsyncBytes = URLSession.Backport.AsyncBytes
	
	var asyncLines: AsyncLineSequence<AsyncBytes> {
		get async throws {
			let (bytes, _) = try await URLSession.shared.backport.bytes(from: self)
			return bytes.lines
		}
	}
	
}
#else // os(Linux) || os(Windows)
extension URL {
	
	var asyncLines: AsyncLineSequence<URL.AsyncBytes> {
		get async throws {
			return self.lines
		}
	}
	
}
#endif // os(Linux) || os(Windows)

//
//  Utilities.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 8/27/21.
//

import Foundation
import Vapor

enum Constants {
	
	/// The current version number for the API. Increment this value every time a breaking change is made to the public-facing API.
	static let apiVersion: UInt = 1
	
	static let datafeedURL: URL = {
		if let itrakString = ProcessInfo.processInfo.environment["ITRAK"] {
			return URL(string: itrakString)!
		} else {
			return URL(string: "https://shuttletracker.app/datafeed")!
		}
	}()
	
}

enum CoordinateUtilities {
	
	static let centerLatitude = 42.735
	
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

public protocol HasDefaultValue: ExpressibleByNilLiteral {
	
	static var defaultValue: Self { get }
	
}

extension HasDefaultValue {
	
	public init(nilLiteral: ()) {
		self = .defaultValue
	}
	
}

extension String: HasDefaultValue {
	
	public static let defaultValue = ""
	
}

extension Int: HasDefaultValue {
	
	public static let defaultValue = 0
	
}

extension Float: HasDefaultValue {
	
	public static let defaultValue: Float = 0
	
}

extension Double: HasDefaultValue {
	
	public static let defaultValue: Double = 0
	
}

extension Optional: HasDefaultValue {
	
	public static var defaultValue: Wrapped? {
		get {
			return nil
		}
	}
	
}

extension Optional: RawRepresentable where Wrapped: RawRepresentable, Wrapped.RawValue: HasDefaultValue {
	
	public var rawValue: Wrapped.RawValue {
		get {
			if self == nil {
				return .defaultValue
			} else {
				return self.unsafelyUnwrapped.rawValue
			}
		}
	}
	
	public init?(rawValue: Wrapped.RawValue) {
		self = Wrapped(rawValue: rawValue)
	}
	
}

extension Optional: CustomStringConvertible where Wrapped: CustomStringConvertible {
	
	public var description: String {
		get {
			if self == nil {
				return .defaultValue
			} else {
				return self.unsafelyUnwrapped.description
			}
		}
	}
	
}

extension Set: Content, RequestDecodable, ResponseEncodable, AsyncRequestDecodable, AsyncResponseEncodable where Element: Codable { }

extension Optional: Content, RequestDecodable, ResponseEncodable, AsyncRequestDecodable, AsyncResponseEncodable where Wrapped: Codable { }

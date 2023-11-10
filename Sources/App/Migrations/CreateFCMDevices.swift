import FluentKit

struct CreateFCMDevices: VersionedAsyncMigration {
	
	typealias ModelType = FCMDevice
	
	func prepare(
		using schemaBuilder: SchemaBuilder,
		to version: UInt,
		enumFactory: (any DatabaseEnum.Type) async throws -> DatabaseSchema.DataType
	) async throws {
		switch version {
		case 0:
			fatalError("Can’t prepare migration to version 0!")
		case 1:
			try await schemaBuilder
				.id()
				.field("token", .string, .required)
				.unique(on: "token")
				.create()
		default:
			fatalError("Unknown migration version number!")
		}
	}
	
	func revert(using schemaBuilder: SchemaBuilder, to version: UInt) async throws {
		switch version {
		case 0:
			try await schemaBuilder.delete()
		default:
			fatalError("Unknown migration version number!")
		}
	}
	
}

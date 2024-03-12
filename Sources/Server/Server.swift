//
//  Server.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 1/9/24.
//

import APNS
import FluentPostgresDriver
import FluentSQLiteDriver
import NIOSSL
import Queues
import QueuesFluentDriver
import Vapor
import VaporAPNS

@main
struct Server {
	
	static func main() async throws {
		// MARK: - Initialization
		var environment = try Environment.detect()
		try LoggingSystem.bootstrap(from: &environment)
		let application = Application(environment)
		defer {
			application.shutdown()
		}
		
		// MARK: - Middleware
		application.middleware.use(
			CORSMiddleware(
				configuration: .default()
			)
		)
		application.middleware.use(
			FileMiddleware(
				publicDirectory: application.directory.publicDirectory
			)
		)
		
		// MARK: - Databases
		application.databases.use(
			.sqlite(),
			as: .sqlite,
			isDefault: false
		)
		
		var postgresConfiguration: SQLPostgresConfiguration
		if let postgresURLString = ProcessInfo.processInfo.environment["DATABASE_URL"], let postgresURL = URL(string: postgresURLString) {
			postgresConfiguration = try SQLPostgresConfiguration(url: postgresURL)
			postgresConfiguration.coreConfiguration.tls = .disable // TLS is unnecessary because the database is hosted on the same machine as this server.
		} else {
			guard let hostname = ProcessInfo.processInfo.environment["POSTGRES_HOSTNAME"] else {
				fatalError("No database URL was specified, but the Postgres hostname is undefined. Remember to set the POSTGRES_HOSTNAME environment variable!")
			}
			let port = ProcessInfo.processInfo.environment["POSTGRES_PORT"].flatMap { (rawPort) in
				return Int(rawPort)
			}
			guard let username = ProcessInfo.processInfo.environment["POSTGRES_USERNAME"] else {
				fatalError("No database URL was specified, but the Postgres username is undefined. Remember to set the POSTGRES_USERNAME environment variable!")
			}
			let password = ProcessInfo.processInfo.environment["POSTGRES_PASSWORD"]
			if password == nil {
				print("No database URL was specified, but the Postgres password is undefined. If this is unexpected, then remember to set the POSTGRES_PASSWORD environment variable.")
			}
			
			// TODO: Make a new database during the setup process
			// For now, we’re using the default PostgreSQL database for deployment-compatibility reasons, but we should in the future switch to a non-default, unprotected database.
			postgresConfiguration = SQLPostgresConfiguration(
				hostname: hostname,
				port: port ?? SQLPostgresConfiguration.ianaPortNumber,
				username: username,
				password: password,
				tls: .disable
			)
		}
		application.databases.use(
			.postgres(configuration: postgresConfiguration),
			as: .psql,
			isDefault: false
		)
		
		// MARK: - Migrations
		application.migrations.add(
			CreateBuses(),
			CreateRoutes(),
			CreateStops(),
			JobMetadataMigrate(),
			to: .sqlite
		) // Add to the SQLite database
		try await application.autoMigrate()
		
		let migrator: VersionedMigrator
		do {
			migrator = try await VersionedMigrator(database: application.db(.psql))
		} catch let error as PSQLError {
			if case .connectionError = error.code {
				fatalError("The server failed to connect to the PostgreSQL database. Ensure that the database service is active. If you’re not using port \(SQLPostgresConfiguration.ianaPortNumber), then remember to set the POSTGRES_PORT environment variable!")
			} else {
				throw error
			}
		}
		try await migrator.migrate(CreateAnalyticsEntries())
		try await migrator.migrate(CreateAnnouncements())
		try await migrator.migrate(CreateAPNSDevices())
		try await migrator.migrate(CreateLogs())
		try await migrator.migrate(CreateMilestones())
		
		// MARK: - Jobs
		application.queues.use(.fluent(.sqlite))
		application.queues
			.schedule(BusDownloadingJob())
			.minutely()
			.at(0)
		application.queues
			.schedule(GPXImportingJob())
			.daily()
			.at(.midnight)
		application.queues
			.schedule(LocationRemovalJob())
			.everySecond()
		application.queues
			.schedule(RestartJob())
			.at(Date.now + 21600)
		try application.queues.startInProcessJobs()
		try application.queues.startScheduledJobs()
		
		// MARK: - APNS
		if let apnsKeyPath = ProcessInfo.processInfo.environment["APNS_KEY"] {
			guard let keyIdentifier = ProcessInfo.processInfo.environment["APNS_KEY_IDENTIFIER"] else {
				fatalError("An APNS key was specified, but no key identifier is set. Remember to set the APNS_KEY_IDENTIFIER environment variable!")
			}
			guard let teamIdentifier = ProcessInfo.processInfo.environment["APNS_TEAM_IDENTIFIER"] else {
				fatalError("An APNS key was specified, but no team identifier is set. Remember to set the APNS_TEAM_IDENTIFIER environment variable!")
			}
			application.apns.containers.use(
				APNSClientConfiguration(
					authenticationMethod: .jwt(
						privateKey: try .loadFrom(string: String(contentsOfFile: apnsKeyPath)),
						keyIdentifier: keyIdentifier,
						teamIdentifier: teamIdentifier
					),
					environment: .production
				),
				eventLoopGroupProvider: .shared(application.eventLoopGroup),
				responseDecoder: JSONDecoder(),
				requestEncoder: JSONEncoder(),
				as: .default
			)
		}
		
		// MARK: - TLS
		if FileManager.default.fileExists(atPath: "tls") {
			print("TLS directory detected!")
			try application.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
				certificateChain: [
					.certificate(
						NIOSSLCertificate(
							file: "\(FileManager.default.currentDirectoryPath)/tls/server.crt",
							format: .pem
						)
					)
				],
				privateKey: .privateKey(
					NIOSSLPrivateKey(
						file: "\(FileManager.default.currentDirectoryPath)/tls/server.key",
						format: .pem
					)
				)
			)
		} else if let domain = ProcessInfo.processInfo.environment["DOMAIN"] {
			try application.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
				certificateChain: [
					.certificate(
						NIOSSLCertificate(
							file: "/etc/letsencrypt/live/\(domain)/fullchain.pem",
							format: .pem
						)
					)
				],
				privateKey: .file(
					"/etc/letsencrypt/live/\(domain)/privkey.pem"
				)
			)
		}
		
		// MARK: - HTTP Routes
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		try application.register(collection: RedirectsController())
		try application.register(collection: VersionController(), on: "version")
		try application.register(collection: DataFeedController(), on: "datafeed")
		try application.register(collection: ScheduleController(), on: "schedule")
		try application.register(collection: BusesController(decoder: decoder), on: "buses")
		try application.register(collection: StopsController(), on: "stops")
		try application.register(collection: RoutesController(), on: "routes")
		try application.register(collection: AnnouncementsController(decoder: decoder), on: "announcements")
		try application.register(collection: MilestonesController(decoder: decoder), on: "milestones")
		try application.register(collection: LogsController(decoder: decoder), on: "logs")
		try application.register(collection: AnalyticsController(decoder: decoder), on: "analytics")
		try application.register(collection: NotificationsController(), on: "notifications")
		
		// MARK: - Startup
		for busID in Buses.shared.allBusIDs {
			try await Bus(id: busID)
				.save(on: application.db(.sqlite))
		}
		try? await BusDownloadingJob()
			.run(context: application.queues.queue.context)
		try await GPXImportingJob()
			.run(context: application.queues.queue.context)
		try await application.execute()
	}
	
}

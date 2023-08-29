//
//  configure.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import FluentPostgresDriver
import FluentSQLiteDriver
import NIOSSL
import Queues
import QueuesFluentDriver
import Vapor

public func configure(_ application: Application) async throws {
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
	
	let migrator = try await VersionedMigrator(database: application.db(.psql))
	try await migrator.migrate(CreateAnalyticsEntries())
	try await migrator.migrate(CreateAnnouncements())
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
		.at(Date() + 21600)
	try application.queues.startInProcessJobs()
	try application.queues.startScheduledJobs()
	
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
	
	// MARK: - Startup
	for busID in Buses.shared.allBusIDs {
		try await Bus(id: busID)
			.save(on: application.db(.sqlite))
	}
	try? await BusDownloadingJob()
		.run(context: application.queues.queue.context)
	try await GPXImportingJob()
		.run(context: application.queues.queue.context)
	try routes(application)
}

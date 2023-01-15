//
//  configure.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import NIOSSL
import Vapor
import FluentSQLiteDriver
import FluentPostgresDriver
import Queues
import QueuesFluentDriver

public func configure(_ application: Application) async throws {
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
	application.databases.use(
		.sqlite(),
		as: .sqlite,
		isDefault: true
	)
	if let postgresURLString = ProcessInfo.processInfo.environment["DATABASE_URL"], let postgresURL = URL(string: postgresURLString) {
		application.databases.use(
			try .postgres(url: postgresURL),
			as: .psql,
			isDefault: false
		)
	} else {
		let postgresHostname = ProcessInfo.processInfo.environment["POSTGRES_HOSTNAME"]!
		let postgresUsername = ProcessInfo.processInfo.environment["POSTGRES_USERNAME"]!
		let postgresPassword = ProcessInfo.processInfo.environment["POSTGRES_PASSWORD"] ?? ""
		
		// TODO: Make a new database during the setup process
		// For now, we’re using the default PostgreSQL database for deployment compatibility reasons, but we should in the future switch to a non-default, unprotected database.
		application.databases.use(
			.postgres(
				hostname: postgresHostname,
				username: postgresUsername,
				password: postgresPassword
			),
			as: .psql,
			isDefault: false
		)
	}
	application.migrations.add(
		CreateBuses(),
		CreateRoutes(),
		CreateStops(),
		JobModelMigrate()
	) // Add to the default database
	application.migrations.add(
		CreateAnnouncements(),
		CreateAnalyticsEntries(),
		CreateLogs(),
		CreateMilestones(),
		to: .psql
	) // Add to the persistent database
	application.queues.use(
		.fluent(useSoftDeletes: false)
	)
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
	try await application.autoMigrate()
	try application.queues.startInProcessJobs()
	try application.queues.startScheduledJobs()
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
	for busID in Buses.shared.allBusIDs {
		try await Bus(id: busID)
			.save(on: application.db)
	}
	try? await BusDownloadingJob()
		.run(context: application.queues.queue.context)
	try await GPXImportingJob()
		.run(context: application.queues.queue.context)
	try routes(application)
	}

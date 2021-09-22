//
//  configure.swift
//  Shuttle Tracker Server
//
//  Created by Gabriel Jacoby-Cooper on 9/21/20.
//

import NIOSSL
import Vapor
import FluentSQLiteDriver
import Queues
import QueuesFluentDriver

public func configure(_ application: Application) throws {
	application.middleware.use(CORSMiddleware(configuration: .default()))
	application.middleware.use(FileMiddleware(publicDirectory: application.directory.publicDirectory))
	application.databases.use(.sqlite(), as: .sqlite)
	application.migrations.add(CreateBuses(), CreateRoutes(), CreateStops(), JobModelMigrate())
	application.queues.use(.fluent(useSoftDeletes: false))
	application.queues.schedule(BusDownloadingJob())
		.minutely()
		.at(0)
	application.queues.schedule(GPXImportingJob())
		.daily()
		.at(.midnight)
	application.queues.schedule(LocationRemovalJob())
		.everySecond()
	try application.autoMigrate()
		.wait()
	try application.queues.startInProcessJobs()
	try application.queues.startScheduledJobs()
	if FileManager.default.fileExists(atPath: "tls") {
		print("TLS directory detected!")
		try application.http.server.configuration.tlsConfiguration = .forServer(
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
		try application.http.server.configuration.tlsConfiguration = .forServer(
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
	_ = BusDownloadingJob().run(context: application.queues.queue.context)
	_ = GPXImportingJob().run(context: application.queues.queue.context)
	try routes(application)
}

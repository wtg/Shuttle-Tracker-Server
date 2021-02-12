//
//  StopDownloadingJob.swift
//  
//
//  Created by Gabriel Jacoby-Cooper on 10/20/20.
//

import Queues

struct StopDownloadingJob: ScheduledJob {
	
	func run(context: QueueContext) -> EventLoopFuture<Void> {
		[Stop].download(application: context.application) { (stops) in
			Stop.query(on: context.application.db)
				.all()
				.mapEach { (stop) in
					_ = stop.delete(on: context.application.db)
				}
				.whenSuccess { (_) in
					stops.save(on: context.application.db)
				}
		}
		return context.eventLoop.future()
	}
	
}

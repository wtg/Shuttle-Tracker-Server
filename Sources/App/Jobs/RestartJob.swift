//
//  RestartJob.swift
//  ShuttleTrackerServer
//
//  Created by Gabriel Jacoby-Cooper on 9/29/21.
//

import Queues

struct RestartJob: ScheduledJob {
	
	func run(context: QueueContext) -> EventLoopFuture<Void> {
		context.application.shutdown()
		return context.eventLoop.future()
	}
	
}

//
//  RestartJob.swift
//  ShuttleTrackerServer
//
//  Created by Gabriel Jacoby-Cooper on 9/29/21.
//

import Queues

/// A job that restarts (_i.e._, shuts down in preparation for automatic restoration) the server.
struct RestartJob: AsyncScheduledJob {
	
	func run(context: QueueContext) {
		context.application.shutdown()
	}
	
}

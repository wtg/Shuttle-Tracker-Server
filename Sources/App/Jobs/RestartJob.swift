//
//  RestartJob.swift
//  ShuttleTrackerServer
//
//  Created by Gabriel Jacoby-Cooper on 9/29/21.
//

import Queues

struct RestartJob: AsyncScheduledJob {
	
	func run(context: QueueContext) {
		context.application.shutdown()
	}
	
}

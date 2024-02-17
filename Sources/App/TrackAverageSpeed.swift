import Foundation
import Queues

func calculateAverageSpeedlimit() {
    var allData = parseCSV()

    // Collection to hold all of the necessary data
    var allSpeedlimits: [Double]
    var differenceInDistance: [Double]
    var differenceInTime: [Int]


    // Create a bus to use some functions
    var first_location: Coordinate = allData[0].coordinate
    var firstDate: Date = allData[0].date
    var firstBusType: Bus.Location.LocationType = allData[0].type

    var firstUUID: UUID = UUID()
    var firstBusLocation: Bus.Location = Bus.Location(id: firstUUID, date: firstDate, coordinate: first_location, type: firstBusType)

    var index: Int = 1

    while (index < 10 ) {
        var second_location: Coordinate = allData[index].coordinate
        var secondDate: Date = allData[index].date
        var secondBusType: Bus.Location.LocationType = allData[index].type

        var secondUUID: UUID = UUID()
        var secondBusLocation: Bus.Location = Bus.Location(id: secondUUID, date: secondDate, coordinate: second_location, type: secondBusType)

        var timeSincelastLocation: Double = firstDate.distance(to: secondDate)

        first_location = allData[index].coordinate
        firstDate = allData[index].date


        // func run(context: QueueContext) async throws {
        //     let routes = try await Route
        //         .query(on: context.application.db(.sqlite))
        //         .all()
        //         .filter { (route) in 
        //             return route.schedule.isActive
        //         }
        //     for route in routes {
        //         if (route.checkIsOnRoute(location: firstBusLocation) && route.checkIsOnRoute(location: secondBusLocation)) {
        //             var firsttotalDistance: Double = route.getTotalDistanceTraveled(location: first_location)
        //             var secondTotalDistance: Double = route.getTotalDistanceTraveled(location: second_location)
        //         }
        //     }
        // }
        


        index += 1
    }

    
    
}
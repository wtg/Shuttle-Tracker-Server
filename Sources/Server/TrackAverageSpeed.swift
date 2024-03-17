import Foundation
import Queues
import Fluent
import Vapor
import VaporAPNS

// calculates speed into mph given distance in meters and seconds
func calculateSpeed(distance: Double, time: Int) -> Double {
    // convert seconds to hour
    let hour: Double = Double(time)/3600
    
    // convert meters to miles
    let miles: Double = distance * 0.00062137

    let mph: Double = miles/hour

    // rounds to three decimal places
    return Double(round(1000 * mph) / 1000)
}


func calculateAverageSpeedlimit(db: (DatabaseID?) -> any Database) async throws {
    let allData = parseCSV()

    // get the routes from the database to use route class' methods/functions
    let routes = try await Route
            .query(on: db(.sqlite))
            .all()
            .filter { (route) in
				return route.schedule.isActive
			}

    // @key Bus number
    // @value: An array of all the speed limits of the bus 
    var mapOfAllBusesSpeed: [Int: [Double]] = [Int:[Double]]()

    // tracks the first and second location to compare
    var first_location: [Int: Coordinate] = [Int:Coordinate]()
    var firstDate: [Int: Date] = [Int:Date]()
    var firstBusType: [Int: Bus.Location.LocationType] = [Int:Bus.Location.LocationType]()

    var second_location: [Int: Coordinate] = [Int:Coordinate]()
    var secondDate: [Int: Date] = [Int:Date]() 
    var secondBusType: [Int: Bus.Location.LocationType] = [Int:Bus.Location.LocationType]()
    
    // Tracks the speeds based on the section/distance traveled
    var currentSpeeds: [Int: [Double]] = [Int:[Double]]()

    // keeps track of the total distances and time that has passed
    var totalDistanceTraveled: [Int:Double] = [Int:Double]()
    var totalTimePassed: [Int:Int] = [Int:Int]()

    // keeps track of what the current day of the bus is on
    var currentDays: [Int: DateComponents] = [Int:DateComponents]()

    var index: Int = 0
    var currentBus: Int = allData[0].bus_number

    while (index < 240 ) { 
        currentBus = allData[index].bus_number

        // Calculate the speed after >= 500 meters
        if (totalDistanceTraveled[currentBus,default: 0] >= 500) {
            currentSpeeds[currentBus, default: []].append(calculateSpeed(distance: totalDistanceTraveled[currentBus,default: 0], time: totalTimePassed[currentBus,default: 0]))
        }

        // initialize the first date for the current bus
        if (currentDays[currentBus] == nil) {
            currentDays[currentBus] = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: allData[index].date)
        }

        // initialize the first location for the current bus and we skip to next location
        if (first_location[currentBus] == nil) {
            first_location[currentBus] = allData[index].coordinate
            firstDate[currentBus] = allData[index].date
            firstBusType[currentBus] = allData[index].type
            index += 1
            continue
        }

        // set what the second location is
        second_location[currentBus] =  allData[index].coordinate
        secondDate[currentBus] =  allData[index].date
        secondBusType[currentBus] = allData[index].type


        let timeSincelastLocation: Int = Int(firstDate[currentBus]!.distance(to: secondDate[currentBus]!))

        // check for the end date
        var endDate = DateComponents()
        let currentTime = Calendar.current.dateComponents([.day, .year, .month, .hour, .minute, .second], from: Calendar.current.date(from: currentDays[currentBus]!)!)
        endDate.year = currentTime.year
        endDate.month = currentTime.month
        endDate.day = currentTime.day! + 1
        endDate.hour = 3
        endDate.minute = 0 
        endDate.second = 0 



        /* 
        *  Filtering out the datas by days 
        *  We will clear all the information/data that we have taken so far 
        *  and clear them at the end of the day/end of the schedule
        */
        if (allData[index].date > Calendar.current.date(from: endDate)!) {
            let distance: Double = totalDistanceTraveled[currentBus, default: 0]
            let time: Int = totalTimePassed[currentBus, default: 0]
            
            // change the current day to whatever the last known date was
            currentDays[currentBus] = Calendar.current.dateComponents([.day, .year, .month, .hour, .minute, .second],from: allData[index].date)

            // calculate the overall speed of one trip
            mapOfAllBusesSpeed[currentBus, default: []].append(calculateSpeed(distance: distance, time: time))

            totalDistanceTraveled[currentBus] = 0
            totalTimePassed[currentBus] = 0
            currentSpeeds.removeAll()
        }
    
        // we keep track of the total distance/time everytime the bus moves
        for route in routes {
            // check if the bus/user location is on a route
            if (route.checkIsNearby(location: first_location[currentBus]!) && route.checkIsNearby(location: second_location[currentBus]!)) {
                let firstTotalDistance: Double = route.getTotalDistanceTraveled(location: first_location[currentBus]!)
                let secondTotalDistance: Double = route.getTotalDistanceTraveled(location: second_location[currentBus]!)
                // the bus may just sit at the same spot and wait to move, so we don't want to use that distance
                // edge case for sitting at union or sitting at a stop for a while
                if (abs(secondTotalDistance-firstTotalDistance) < 20 && totalTimePassed[currentBus, default: 0] > 60) {
                    break   
                }
                totalDistanceTraveled[currentBus] = totalDistanceTraveled[currentBus, default:0] + abs(secondTotalDistance - firstTotalDistance)
                totalTimePassed[currentBus] = totalTimePassed[currentBus,default: 0] + timeSincelastLocation
            }
        }

        // replace the first location with this location to compare for index + 1
        first_location[currentBus] =  allData[index].coordinate
        firstDate[currentBus] =  allData[index].date
        firstBusType[currentBus] = allData[index].type

        index += 1
    }

}
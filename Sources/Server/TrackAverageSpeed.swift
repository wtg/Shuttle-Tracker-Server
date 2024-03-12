import Foundation
import Queues
import Fluent
import Vapor
import VaporAPNS

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
    var allData = parseCSV()
    var allBusNumbers: Set<Int> = getAllBusNumbers()

    // @key Bus number
    // @value: An array of all the speed limits of the bus 
    var mapOfAllBusesSpeed: [Int: [Double]] = [:]

    //
    var currentBus: Int = allData[0].bus_number
   
    var first_location: [Int: Coordinate] = [:]
    var firstDate: [Int: Date] = [:]
    var firstBusType: [Int: Bus.Location.LocationType] = [:]

    var second_location: [Int: Coordinate] = [:]
    var secondDate: [Int: Date] = [:]
    var secondBusType: [Int: Bus.Location.LocationType] = [:]

    // initialize all variables to the first data even if it is not correct, corresponding to busNumber
    for busNumber in allBusNumbers {
        first_location[busNumber] = allData[0].coordinate
        second_location[busNumber] = allData[0].coordinate

        firstDate[busNumber] = allData[0].date
        secondDate[busNumber] = allData[0].date

        firstBusType[busNumber] = allData[0].type
        secondBusType[busNumber] = allData[0].type
    }
    

    // var first_location: [Int: Coordinate] = Dictionary<Int, Coordinate>()
    // var firstDate: [Int: Date] = Dictionary<Int, Date>()
    // var firstBusType: [Int: Bus.Location.LocationType] = Dictionary<Int, Bus.Location.LocationType>()
    
    // initialize the first bus/location
    // first_location[allBusNumbers.first] = allData[0].coordinate
    // firstDate[allBusNumbers.first] = allData[0].date
    // firstBusType[allBusNumbers.first] = allData[0].type

    // var second_location: [Int: Coordinate] = Dictionary<Int, Coordinate>()
    // var secondDate: [Int: Date] = Dictionary<Int, Date>() 
    // var secondBusType: [Int: Bus.Location.LocationType] = Dictionary<Int, Bus.Location.LocationType>()


    var firstUUID: UUID = UUID()
    // var firstBusLocation: Bus.Location = Bus.Location(id: firstUUID, date: firstDate, coordinate: first_location, type: firstBusType)
    var firstBusLocation: Bus.Location = Bus.Location(id: firstUUID, date: firstDate[currentBus]!, coordinate: first_location[currentBus]!, type: firstBusType[currentBus]!)


    var index: Int = 1

    // Collections used to collect data neccessary
    var currentSpeeds: [Int: [Double]] = [:]

    // @key: Bus Number
    // @value: Their total distance traveled or total time passed 
    var totalDistanceTraveled: [Int:Double] = [:]
    var totalTimePassed: [Int:Int] = [:]
    var currentDays: [Int: DateComponents] = [:]
    for busNumber in allBusNumbers {
        totalDistanceTraveled[busNumber] = 0.0
        totalTimePassed[busNumber] = 0
        currentDays[busNumber] = Calendar.current.dateComponents([.day, .year, .month], from: allData[0].date)
        currentSpeeds[busNumber] = []
    }


    while (index < 240 ) { 
        currentBus = allData[index].bus_number

        let currentDate: Date = allData[index].date
        let calendarDate = Calendar.current.dateComponents([.day, .year, .month, .hour, .minute, .second], from: currentDate)
        
        // change the current day from the initialized date
        if (Calendar.current.date(from:currentDays[currentBus]!)! == allData[0].date) {
            currentDays[currentBus] = calendarDate
        }

        // check if there is a first location to compare from this currentBus
        // if doesn't exist, first check if the location exists on the route
        // then change first_location to this current index's data and then continue
        // so we don't change secondLocation or compute the speed 

        second_location[currentBus] =  allData[index].coordinate
        secondDate[currentBus] =  allData[index].date
        secondBusType[currentBus] = allData[index].type

        let secondUUID: UUID = UUID()
        let secondBusLocation: Bus.Location = Bus.Location(id: secondUUID, date: secondDate[currentBus]!, coordinate: second_location[currentBus]!, type: secondBusType[currentBus]!)

        let timeSincelastLocation: Int = Int(firstDate[currentBus]!.distance(to: secondDate[currentBus]!))

        // check for the end date
        var endDate = DateComponents()
        let currentTime = Calendar.current.dateComponents([.day, .year, .month, .hour, .minute, .second], from: Calendar.current.date(from: currentDays[currentBus]!)!)

        endDate.year = currentTime.year
        endDate.month = currentTime.month
        endDate.day = currentTime.day
        endDate.hour = 1
        endDate.minute = 0 
        endDate.second = 0 


        /* 
        *  Filtering out the datas by days 
        *  We will clear all the information/data that we have taken so far 
        *  and clear them at the end of the day
        */
        if (allData[index].date > Calendar.current.date(from: endDate)!) {
            var distance: Double = totalDistanceTraveled[currentBus]!
            var time: Int = totalTimePassed[currentBus]!
            
            // change the current day to whatever the last known date was
            currentDays[currentBus] = Calendar.current.dateComponents([.day, .year, .month, .hour, .minute, .second],from: allData[index].date)

            mapOfAllBusesSpeed[currentBus, default: []].append(calculateSpeed(distance: distance, time: time))

            totalDistanceTraveled[currentBus] = 0
            totalTimePassed[currentBus] = 0
            currentSpeeds.removeAll()
        }

        let routes = try await Route
            .query(on: db(.sqlite))
            .all()
            .filter { (route) in
				return route.schedule.isActive
			}
        for route in routes {
            // check if the bus/user location is on a route
            if (route.checkIsNearby(location: firstBusLocation.coordinate) && route.checkIsNearby(location: secondBusLocation.coordinate)) {
                let firstTotalDistance: Double = route.getTotalDistanceTraveled(location: first_location[currentBus]!)
                let secondTotalDistance: Double = route.getTotalDistanceTraveled(location: second_location[currentBus]!)
                // the bus may just sit at the same spot and wait to move, so we don't want to use that distance
                // edge case for sitting at union 
                if (abs(secondTotalDistance-firstTotalDistance) < 20 && totalTimePassed[currentBus]! > 60) {
                    continue
                }
                totalDistanceTraveled[currentBus] = totalDistanceTraveled[currentBus]! + abs(secondTotalDistance - firstTotalDistance)
                totalTimePassed[currentBus] = totalTimePassed[currentBus]! + timeSincelastLocation
            }
        }

        // replace the first location with this location to compare for index + 1
        first_location[currentBus] =  allData[index].coordinate
        firstDate[currentBus] =  allData[index].date
        firstBusType[currentBus] = allData[index].type
        firstUUID = UUID()
        firstBusLocation = Bus.Location(id: firstUUID, date: firstDate[currentBus]!, coordinate: first_location[currentBus]!, type: firstBusType[currentBus]!)

        index += 1
    }

    // find the overall speed from all the different days
    var finalSpeeds: [Int: Double] = Dictionary<Int, Double>()
    for busNumber in allBusNumbers {
        let speeds: [Double] = mapOfAllBusesSpeed[busNumber]!
        var totalSpeed: Double = 0
        var count: Int = 0
        for index in speeds.startIndex ... speeds.endIndex {
            totalSpeed += speeds[index]
            count += 1
        }
        finalSpeeds[busNumber, default: 0] = (totalSpeed/Double(count))
    }   
}
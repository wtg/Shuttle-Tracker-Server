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

    // rounds to five decimal places
    return Double(round(1000 * mph) / 100000)
}

func calculateTime(route: String, distance: Double, index: Int) -> Double {
    // equates to 1 mph
    var mpm = 26.8224
    var speed: Double = 0
    mpm = (mpm * getSpeedData(routeName: route)[index])

    // minutes into seconds
    return (Double(distance)/mpm)*60
}


// global variable to allow for other files to access this data
var west: [Double] = [Double]()
var north: [Double] = [Double]()

var overallWestSpeed: Double = 0
var overallNorthSpeed: Double = 0

var allActiveRoutes: [Route] = [Route]()


// return the global variables of the data obtained
func getSpeedData(routeName: String) -> [Double] {
    if (routeName == "West Route") {
        return west
    }
    return north
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
    
    allActiveRoutes = routes

    // tracks the first and second location to compare
    var first_location: [Int: Coordinate] = [Int:Coordinate]()
    var firstDate: [Int: Date] = [Int:Date]()

    var second_location: [Int: Coordinate] = [Int:Coordinate]()
    var secondDate: [Int: Date] = [Int:Date]() 
    
    // Tracks the average speed per section (every 500 meter)
    var westSpeeds: [Double] = [Double](repeating: 0.0, count: 10)  // represents the average speeds per section of the West Route
    var northSpeeds: [Double] = [Double](repeating: 0.0, count: 10) // represents the average speeds per section of the West Route

    // keeps track of the total distances and time that has passed
    var totalDistanceTraveled: [Int:Double] = [Int:Double]() // tries to track distance and clears every 500m
    var distanceAlongRoute_first: [Int: Double] = [Int:Double]() // contains the total route distance for index-1
    var distanceAlongRoute_second: [Int: Double] = [Int:Double]() // contains the total route distance for index

    var totalTimePassed: [Int:Int] = [Int:Int]()


    // keeps track of what the current day of the bus is on
    var currentDays: [Int: DateComponents] = [Int:DateComponents]()

    var index: Int = 0
    var currentBus: Int = Int()

    while (index < allData.count) { 
        // get the current bus number
        currentBus = allData[index].bus_number

        // initialize the first date for the current bus
        if (currentDays[currentBus] == nil) {
            currentDays[currentBus] = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: allData[index].date)
        }

        // initialize the first location for the current bus and we skip to next location
        if (first_location[currentBus] == nil) {
            first_location[currentBus] = allData[index].coordinate
            firstDate[currentBus] = allData[index].date
            index += 1
            continue
        }

        // set what the second location is
        second_location[currentBus] =  allData[index].coordinate
        secondDate[currentBus] =  allData[index].date

        // check for the end date
        // the endDate will be the next day at 3:00 am
        // endDate.hour = 0 == 4:00 am
        var endDate = DateComponents(minute: 0, second:0)
        let currentTime = Calendar.current.dateComponents([.day, .year, .month, .hour], from: Calendar.current.date(from: currentDays[currentBus]!)!)
        endDate.year = currentTime.year
        endDate.month = currentTime.month
        endDate.day = currentTime.day! + 1
        endDate.hour = -1

        /*
        *  The next step could be to work towards keeping track of morning, afternoon, night data
        *  Speeds will depend on the time of day. Expected speeds: morning > afternoon >= night
        *                                         There tends to be a rush for shuttles in the morning, thus bus drivers driving faster
        *                                         Afternoon and night, there is no rush for shuttles. For night, there is no traffic so drivers might drive faster
        *                                         while also maintaining a safe speed due to the dark
        */
        // // morning starts at 7:00 am
        // var morning: DateComponents = DateComponents(minute: 0, second:0)
        // morning.year = currentTime.year
        // morning.month = currentTime.month
        // morning.day = currentTime.day! + 1
        // morning.hour = 3

        // // afternoon starts at 11:00 am
        // var afterNoon: DateComponents = DateComponents(minute: 0, second:0)
        // afterNoon.year = currentTime.year
        // afterNoon.month = currentTime.month
        // afterNoon.day = currentTime.day! + 1
        // afterNoon.hour = 7

        // // night starts at 5:00 pm
        // var night: DateComponents = DateComponents(minute: 0, second:0)
        // night.year = currentTime.year
        // night.month = currentTime.month
        // night.day = currentTime.day! + 1
        // night.hour = 13

        /* 
        *  Filtering out the datas by days 
        *  We will clear all the information/data that we have taken so far 
        *  and clear them at the end of the day/end of the schedule
        *  We will also change the first_location to this new date and skip to the next index
        */
        if (allData[index].date > Calendar.current.date(from: endDate)!) {            
            // change the current day to whatever the last known date was
            currentDays[currentBus] = Calendar.current.dateComponents([.day, .year, .month, .hour, .minute, .second],from: allData[index].date)
            
            first_location[currentBus] =  allData[index].coordinate
            firstDate[currentBus] =  allData[index].date
            
            distanceAlongRoute_first[currentBus, default: 0] = 0
            distanceAlongRoute_second[currentBus, default: 0] = 0     

            totalDistanceTraveled[currentBus] = 0
            totalTimePassed[currentBus] = 0
            index += 1
            continue
        }

        let timeSincelastLocation: Int = Int(firstDate[currentBus]!.distance(to: secondDate[currentBus]!))

        // we keep track of the total distance/time everytime the bus moves
        for route in routes {
            // check if the bus/user location is on a route
            if (route.checkIsNearby(location: first_location[currentBus]!) && route.checkIsNearby(location: second_location[currentBus]!)) {
                let firstTotalDistance: Double = route.getTotalDistanceTraveled(location: first_location[currentBus]!, distanceAlongRoute: distanceAlongRoute_first[currentBus,default: 0])
                let secondTotalDistance: Double = route.getTotalDistanceTraveled(location: second_location[currentBus]!, distanceAlongRoute: distanceAlongRoute_second[currentBus,default: 0])
                
                distanceAlongRoute_first[currentBus, default: 0] = firstTotalDistance
                distanceAlongRoute_second[currentBus, default: 0] = secondTotalDistance

                totalDistanceTraveled[currentBus, default: 0] += abs(secondTotalDistance - firstTotalDistance)
                totalTimePassed[currentBus, default: 0] += timeSincelastLocation
                    var ind: Int = 0; 
                    ind = Int(route.getTotalDistanceTraveled(location: second_location[currentBus]!)/500)
                    // averages the old average and the new average speed to create a new average speed for this section
                    if (route.name == "West Route") {
                        // there exists a speed average at ind
                        if westSpeeds[ind] != 0 {
                            westSpeeds[ind] += (calculateSpeed(distance: totalDistanceTraveled[currentBus, default: 0], time: totalTimePassed[currentBus, default: 0]))/2
                        }
                        // there does not exist a average at ind
                        else {
                            westSpeeds[ind] = (calculateSpeed(distance: totalDistanceTraveled[currentBus, default: 0], time: totalTimePassed[currentBus, default: 0]))
                        }
                    }
                    else if (route.name == "North Route") {
                        // there exists a speed average at ind
                        if northSpeeds[ind] != 0 {
                            northSpeeds[ind] += (calculateSpeed(distance: totalDistanceTraveled[currentBus, default: 0], time: totalTimePassed[currentBus, default: 0]))/2
                        }
                        // there does not exist a average at ind
                        else {
                            northSpeeds[ind] = (calculateSpeed(distance: totalDistanceTraveled[currentBus, default: 0], time: totalTimePassed[currentBus, default: 0]))
                        }
                    }
                    // reset how far and how long the bus has traveled for
                    totalDistanceTraveled[currentBus] = 0
                    totalTimePassed[currentBus] = 0
            
            }
        }

        // replace the first location with this location to compare for index + 1
        first_location[currentBus] =  allData[index].coordinate
        firstDate[currentBus] =  allData[index].date

        index += 1

    }
    west = westSpeeds
    north = northSpeeds

    // print("West Speeds:")
    // for speed in westSpeeds {
    //     print(speed)
    // }
    // print("\nNorth Speeds:")
    // for speed in northSpeeds {
    //     print(speed)
    // }


    // calculate the overall speed from the data we have gathered
    var totalSpeed: Double = 0
    var count: Double = 0
    for speed in westSpeeds {
        if (speed != 0) {
            totalSpeed += speed
            count += 1
        }
    }
    overallWestSpeed = totalSpeed/count

    totalSpeed = 0
    count = 0
    for speed in northSpeeds {
        if (speed != 0) {
            totalSpeed += speed
            count += 1
        }
    }

    overallNorthSpeed = totalSpeed/count

}

// returns time in seconds of how far until destination
func calculateETA(busLocation: Coordinate, destination: Coordinate) async throws -> Int? {
    for route in allActiveRoutes {
        // if busLocation and destinate is not on the same route, we throw a error
        if (route.checkIsNearby(location: busLocation) == !route.checkIsNearby(location: destination)) {
            return nil
        }
        /*
        *   We calculate the time based off the destination at every 500 m. 
        *   Every 500m we use a different speed which will allow for a more accurate time
        *   time = 500m/speed
        */
        if (route.checkIsNearby(location: busLocation) && route.checkIsNearby(location: destination)) {
            let busDistance: Double = route.getTotalDistanceTraveled(location: busLocation)
            let destinationDistance: Double = route.getTotalDistanceTraveled(location: destination)

            let startIndex: Int = Int(busDistance/500)
            let endIndex: Int = Int(destinationDistance/500)
            /*
            *   There are some things to consider:
            *       1) Destination is ahead of the bus location
            *          - Destination: Union
            */
            // guard let differenceInDistance = (destinationDistance - busDistance) > 0 else {
            //     .abort(.conflict)
            // }
            let differenceInDistance = (destinationDistance - busDistance)

            var totalTime: Double = 0
            for index in startIndex ... endIndex {
                if (index == endIndex) {
                    let remainingDistance: Double = differenceInDistance.truncatingRemainder(dividingBy: 500)
                    totalTime += calculateTime(route: route.name, distance: remainingDistance, index: index)
                }
                else {
                    totalTime += calculateTime(route: route.name, distance: 500, index: index)
                }
            }
            return Int(totalTime)
        }
    }
    
    return 0
}
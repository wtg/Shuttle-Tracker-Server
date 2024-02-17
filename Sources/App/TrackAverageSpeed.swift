import Foundation

func calculateAverageSpeedLimit() {
    var allData = parseCSV()

    // Collection to hold all of the necessary data
    var allSpeedLimits: [Double]
    var differenceInDistance: [Double]
    var differenceInTime: [Int]


    var first_location: Coordinate = allData[0].coordinate
    var firstDate: Date = allData[0].date

    var index: Int = 1

    while (index < 10 ) {
        var second_location: Coordinate = allData[index].coordinate
        var secondDate: Date = allData[index].date

        var timeSinceLastLocation: Double = secondDate.distance(to: firstDate)

        first_location = allData[index].coordinate
        firstDate = allData[index].date

        /*
        *   Call algorithm here
            Read notes on ParseData
        */

        // var first_coordinate: Coordinate = Coordinate(latitude: first_location.0,longitude: first_location.1)
        // var first_totalDistance: Double = getTotalDistanceTraveled()


        index += 1
    }

    
    
}
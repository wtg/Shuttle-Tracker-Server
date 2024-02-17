import Foundation


// Finds the substring to get just the time
func parseDate(str:String) -> String{
    let startIndex = str.index(str.startIndex, offsetBy: 11)
    let endIndex = str.index(str.startIndex, offsetBy: 19)
    return String(str[startIndex..<endIndex])
}

// Returns the total time since 00:00:00 to the time (in seconds)
func parseTime(str:String) -> Int {
    let startHourIndex = str.index(str.startIndex, offsetBy: 0)
    let endHourIndex = str.index(str.startIndex, offsetBy: 2)
    
    let startMinuteIndex = str.index(str.startIndex,offsetBy: 3)
    let endMinuteIndex = str.index(str.startIndex, offsetBy: 5)
    

    let startSecondsIndex = str.index(str.startIndex, offsetBy: 6)
    let endSecondsIndex = str.index(str.startIndex, offsetBy: 8)
    
    let h = str[startHourIndex..<endHourIndex]
    let m = str[startMinuteIndex..<endMinuteIndex]
    let s = str[startSecondsIndex..<endSecondsIndex]

    let hours: Int = Int(String(h))! * 360
    let minutes: Int = Int(String(m))! * 60
    let seconds: Int = Int(String(s))!

    return hours + minutes + seconds
}

func calculateAverageSpeedLimit() {
    var allData = parseCSV()

    // Collection to hold all of the necessary data
    var allSpeedLimits: [Double]
    var differenceInDistance: [Double]
    var differenceInTime: [Int]



    var first_location: (Double,Double) = (allData[0].latitude,allData[0].longitude)
    var firstDate: String = parseDate(str: allData[0].date)
    var firstTime: Int = parseTime(str: firstDate)

    var index: Int = 1

    while (index < 10 ) {
        var second_location: (Double,Double) = (allData[index].latitude,allData[index].longitude)
        var secondDate: String = parseDate(str: allData[index].date)
        var secondTime: Int = parseTime(str: secondDate)

        var timeSinceLastLocation: Int = secondTime-firstTime

        first_location = (allData[index].latitude, allData[index].longitude)
        firstDate = parseDate(str: allData[index].date)
        firstTime = parseTime(str: firstDate)

        /*
        *   Call algorithm here
            Read notes on ParseData
        */

        // var firstBus: Bus.Location = Bus.Location(allData[index-1],allData[index])
        var first_coordinate: Coordinate = Coordinate(latitude: first_location.0,longitude: first_location.1)
        // var first_totalDistance: Double = getTotalDistanceTraveled()


        index += 1
    }

    
    
}
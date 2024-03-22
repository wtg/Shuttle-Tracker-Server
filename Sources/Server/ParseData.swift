import Foundation 


struct locationData {
    var bus_number: Int
    var coordinate: Coordinate
    var date: Date
    var type: Bus.Location.LocationType
}

var allData = [locationData]()
var allBusNumbers: Set<Int> = Set<Int>()

func getAllBusNumbers() -> Set<Int> {
    return allBusNumbers
}


func parseCSV() -> [locationData] {
    // May not always be the same path --> Figure out a way to guarentee the path to this 
    let filepath = "/home/zhoud7/Shuttle-Tracker-Server/Data.csv"
    var data = ""
    do {
        data = try String(contentsOfFile: filepath)
    } catch {
        print(error)
    }

    let rows = data.components(separatedBy: "\n")
    
    var index: Int = 0

    for row in rows {
        let columns = row.components(separatedBy: ",")

        //check that we have enough columns
        if columns.count == 5 {
            let busNumber = Int(columns[0])!

            // convert into coordinate
            let latitude = Double(columns[1])!
            let longitude = Double(columns[2])!
            let coordinate: Coordinate = Coordinate(latitude:latitude, longitude: longitude)

            // convert string to date type
            let dateFormatter = DateFormatter()
            let dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            dateFormatter.dateFormat = dateFormat
            let date = dateFormatter.date(from: columns[3])!


            let type = Bus.Location.LocationType(rawValue: columns[4])!

            let locationData = locationData(bus_number: busNumber, coordinate: coordinate, date:date, type: type)
            allData.append(locationData)
            allBusNumbers.insert(busNumber)
        }

        index += 1
        if (index == 1000) {
            break
        }
    }
    return allData
}

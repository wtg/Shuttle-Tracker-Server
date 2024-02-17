/*
    Change date into Date type
    and fix everything that comes after that
*/

import Foundation 


struct locationData {
    var bus_number: Int
    var latitude: Double
    var longitude: Double
    var date: Date
    var type: String
}

var allData = [locationData]()

// func convertStringToDate(str: String) {
    
// }

func parseCSV() -> [locationData] {
    // guard let filepath = NSBundle.main.path(forResource: "Data", ofType: "csv") else {
    //     return
    // }
    let filepath = "/home/zhoud7/Shuttle-Tracker-Server/Data.csv"
    var data = ""
    do {
        data = try String(contentsOfFile: filepath)
    } catch {
        print(error)
    }

    let rows = data.components(separatedBy: "\n")

    for row in rows {
        let columns = row.components(separatedBy: ",")

        //check that we have enough columns
        if columns.count == 5 {
            let busNumber = Int(columns[0])!
            let latitude = Double(columns[1])!
            let longitude = Double(columns[2])!
            let date: Date = Date(columns[3])!
            let type = columns[4]

            let locationData = locationData(bus_number: busNumber, latitude: latitude, longitude: longitude, date:date, type: type)
            allData.append(locationData)
            
        }
    }
    return allData
}

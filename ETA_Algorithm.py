import csv
import sys 
from datetime import datetime, date

# Parses Data.csv and appends the correct data to their corresponding arrays 
def parseCVS():
    with open("Data.csv", 'r') as csv_file:
        data = []

        for row in csv_file: 
            row = row.replace("\n","")

            # Separates each cell
            busNumber = row.split(",")[0]
            latitude = row.split(",")[1]
            longitude = row.split(",")[2]
            time = row.split(",")[3]
            dataType = row.split(",")[4]
            
            data.append((busNumber, latitude, longitude, time, dataType))
    return data

def parseDate(first,second):
    return (first[0:19],second[0:19])

def parseTime(first,second):
    firstTime = datetime.strptime(first, '%Y-%m-%d %H:%M:%S').time()
    secondTime = datetime.strptime(second, '%Y-%m-%d %H:%M:%S').time()
    return(firstTime,secondTime)

if __name__=="__main__":    
    # keeps track of all of the differences in distances --> every 2 locations data points
    differenceInDistance = []

    # keeps track of all of the differences in time --> every 2 locations data points
    differenceInTime = []

    data = parseCVS()

    index = 2
    first_location = (data[0][1], data[0][2])
    second_location = (data[1][1], data[1][2])

    # parse the string further in order for Python to convert
    # Gets the time to compare
    firstDate,secondDate = parseDate(data[0][3], data[1][3])
    first_time,second_time = parseTime(firstDate,secondDate)

    timeDifference = datetime.combine(date.min,second_time) - datetime.combine(date.min,first_time)
    differenceInTime.append(timeDifference)

    # Assume all arrays have equal size
    # Data.csv has an odd number of data --> Account for it later on
    while (index < len(data)-1):
        index += 1
        if (index % 2 != 0):
            second_location = (data[index][1], data[index][2])
            continue
        first_location = (data[index][1], data[index][2])

        firstDate,secondDate = parseDate(data[index][3], data[index][3])
        first_time,second_time = parseTime(firstDate,secondDate)
        
        timeDifference = datetime.combine(date.min,second_time) - datetime.combine(date.min,first_time)
        differenceInTime.append(timeDifference)

        # Run distance algorithm on first and second location
        # Then subtract the two distances to get the change in distance within the timeDifference

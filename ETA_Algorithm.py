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

def parseDate(*args):
    if len(args) == 1:
        return(args[0][0:19])
    elif (len(args) == 2):
        return (args[0][0:19],args[1][0:19])

def parseTime(*args):
    if len(args) == 1:
        return(datetime.strptime(args[0], '%Y-%m-%d %H:%M:%S')).time()
    elif (len(args) == 2):
        firstTime = datetime.strptime(args[0], '%Y-%m-%d %H:%M:%S').time()
        secondTime = datetime.strptime(args[1], '%Y-%m-%d %H:%M:%S').time()
        return(firstTime,secondTime)

# They bus number matter, they should correlate with their locations
if __name__=="__main__":    
    # keeps track of all of the differences in distances --> every 2 locations data points
    differenceInDistance = []

    # keeps track of all of the differences in time --> every 2 locations data points
    differenceInTime = []

    data = parseCVS()
    index = 1
    first_location = (data[0][1],data[0][2])
    firstDate = parseDate(data[0][3])
    firstTime = parseTime(firstDate)


    # Assume all arrays have equal size
    # Data.csv has an odd number of data --> Account for it later on
    while (filter(lambda x: x[0].startswith('96'), data)):
        index += 1

        second_location = (data[index][1],data[index][2])
        secondDate = parseDate(data[index][3])
        secondTime = parseTime(secondDate)

        timeSinceLastPosition = datetime.combine(date.min,secondTime) - datetime.combine(date.min,firstTime)

        first_location = (data[index][1],data[index][2])
        firstDate = parseDate(data[index][3])
        firstTime = parseTime(firstDate)
        # Filter by bus since each bus will start at different locations
        
        # Run distance algorithm on first and second location
        # Then subtract the two distances to get the change in distance within the timeDifference

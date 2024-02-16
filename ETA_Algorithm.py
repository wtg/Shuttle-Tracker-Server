import csv
import sys 
from datetime import datetime, date

"""
    Things to keep in mind, notes:

        1) We are finding the distances in between each new location, ie: loc[0] and loc[1] and finding the avg speed limit in between those two
            - There might be a correlation between user/system
            - There might be a correlation between the sections of the route or there could be an avg speed limit throughout the route ==> The sections of the route are roughly the same with each other

        2) Filter by bus since each bus will start at different locations

"""

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
    # while (filter(lambda x: x[0].startswith('96'), data)):
    while (index < 10):
        second_location = (data[index][1],data[index][2])
        secondDate = parseDate(data[index][3])
        secondTime = parseTime(secondDate)

        timeSinceLastPosition = datetime.combine(date.min,secondTime) - datetime.combine(date.min,firstTime)
        print(timeSinceLastPosition)

        first_location = (data[index][1],data[index][2])
        firstDate = parseDate(data[index][3])
        firstTime = parseTime(firstDate)

        index += 1

        """
            We run the algorithm here
            We will get the total distance traveled by position 1 and position 2
                Using these two total distances, we subtract them to find the change in distances ==> delta1
            We will use the time difference found above and subtract time2 by time1 ==> delta2

            Convert the distance into mi or ft as the total distance will return a Double in meters
                avg speed limit = delta1/delta2
            This will be one of the speed limit 
                --> Append into the array that will contain all of the changes in speed limit 
        """
        


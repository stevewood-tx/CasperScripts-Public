#!/bin/sh

# Name: updateBuildingRoomNum.sh
# Date: 07 January 2016
# Author: Steve Wood (swood@integer.com) 
# Purpose: used to read in lease data from a CSV file and update the record in the JSS
# The CSV file needs to be saved as a UNIX file with LF, not CR
# Version: 1.0
#
#
# A good portion of this script is re-purposed from the script posted in the following JAMF Nation article:
#
#  https://jamfnation.jamfsoftware.com/discussion.html?id=13118#respond
#
# USAGE: updateBuildingRoomNum.sh apiusername apipass csvfile.csv

args=("$@")
jssAPIUsername="${args[0]}"
jssAPIPassword="${args[1]}"
jssAddress="<jss address>"
file="${args[2]}"

#Verify we can read the file
data=`cat $file`
if [[ "$data" == "" ]]; then
	echo "Unable to read the file path specified"
	echo "Ensure there are no spaces and that the path is correct"
	exit 1
fi

#Find how many computers to import
computerqty=`awk -F, 'END {printf "%s\n", NR}' $file`
echo "Computerqty= " $computerqty
#Set a counter for the loop
counter="0"

duplicates=[]

#Loop through the CSV and submit data to the API
while [ $counter -lt $computerqty ]
do
	counter=$[$counter+1]
	line=`echo "$data" | head -n $counter | tail -n 1`
        deviceName=`echo "$line" | awk -F , '{print $1}'`
	serialNumber=`echo "$line" | awk -F , '{print $2}'`
	building=`echo "$line" | awk -F , '{print $3}'`
	room=`echo "$line" | awk -F , '{print $4}'`
	
	echo "Attempting to update data for $serialNumber"

	apiData="<mobile_device><location><building>$building</building><room>$room</room></location></mobile_device>"
	output=`curl -sS -k -i -u ${jssAPIUsername}:${jssAPIPassword} -X PUT -H "Content-Type: text/xml" -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>$apiData" ${jssAddress}/JSSResource/mobiledevices/serialnumber/$serialNumber`

	error=""
	error=`echo $output | grep "Conflict"`
	if [[ $error != "" ]]; then
		duplicates+=($serialnumber)
	fi

done

echo "The following computers could not be created:"
printf -- '%s\n' "${duplicates[@]}"

exit 0

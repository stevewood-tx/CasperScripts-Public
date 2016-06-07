#!/bin/bash

# Name: leaseupdate.sh
# Date: 9 March 2015 (Updated 12 November 2015)
# Author: Steve Wood (swood@integer.com) 
# Purpose: used to read in lease data from a CSV file and update the record in the JSS
# The CSV file needs to be saved as a UNIX file with LF, not CR
# Version: 2.0
#
# A good portion of this script is re-purposed from the script posted in the following JAMF Nation article:
#
#  https://jamfnation.jamfsoftware.com/discussion.html?id=13118#respond
#

args=("$@")
jssAPIUsername="${args[0]}"
jssAPIPassword="${args[1]}"
jssAddress="https://your.jss.com:8443"
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
	serialNumber=`echo "$line" | awk -F , '{print $1}'`
	leaseExpires=`echo "$line" | awk -F , '{print $2}'`
	
	echo "Attempting to update lease data for $serialNumber"

	apiData="<computer><purchasing><lease_expires>$leaseExpires</lease_expires></purchasing></computer>"
	output=`curl -sS -k -i -u ${jssAPIUsername}:${jssAPIPassword} -X PUT -H "Content-Type: text/xml" -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>$apiData" ${jssAddress}/JSSResource/computers/id/$myID`

	echo $output
	#Error Checking
	error=""
	error=`echo $output | grep "Conflict"`
	if [[ $error != "" ]]; then
		duplicates+=($serialnumber)
	fi

done

echo "The following computers could not be created:"
printf -- '%s\n' "${duplicates[@]}"

exit 0

#!/bin/sh

# Name: updateAssetTags.sh
# Date: 17 June 2015
# Author: Steve Wood (swood@integer.com) 
# Purpose: used to read in asset tag data from a CSV file and update the record in the JSS
# This script is written for updating a mobile device in the JSS but can be altered for a computer
# by simply changing the <mobile_device> and </mobile_device> tags to <computer> and </computer>
#
# The CSV file needs to be saved as a UNIX file with LF, not CR
# Version: 1.1 - changed to taking name of CSV on command line: /path/to/updateAssetTags.sh /path/to/CSV.file
#
# A good portion of this script is re-purposed from the script posted in the following JAMF Nation article:
#
#  https://jamfnation.jamfsoftware.com/discussion.html?id=13118#respond
#

jssAPIUsername="<apiuser>"
jssAPIPassword="<apipassword>"
jssAddress="https://your.jss.com:8443"
file="$1"

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

id=$((id+1))

#Loop through the CSV and submit data to the API
while [ $counter -lt $computerqty ]
do
	counter=$[$counter+1]
	line=`echo "$data" | head -n $counter | tail -n 1`
	serialNumber=`echo "$line" | awk -F , '{print $1}'`
	assetTag=`echo "$line" | awk -F , '{print $2}'`
	
	echo "Attempting to update lease data for $serialNumber"
	
	echo $serialNumber " " $myID " " $assetTag
	apiData="<mobile_device><general><asset_tag>$assetTag</asset_tag></general></mobile_device>"
	output=`curl -sS -k -i -u ${jssAPIUsername}:${jssAPIPassword} -X PUT -H "Content-Type: text/xml" -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>$apiData" ${jssAddress}/JSSResource/mobiledevices/serialnumber/$serialNumber`

	#Error Checking
	error=""
	error=`echo $output | grep "Conflict"`
	if [[ $error != "" ]]; then
		duplicates+=($serialnumber)
	fi
	#Increment the ID variable for the next user
	id=$((id+1))
done

echo "The following mobile devices could not be updated:"
printf -- '%s\n' "${duplicates[@]}"

exit 0

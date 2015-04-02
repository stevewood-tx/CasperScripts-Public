#!/bin/sh

# Name: leaseupdate.sh
# Date: 9 March 2015
# Author: Steve Wood (swood@integer.com) 
# Purpose: used to read in lease data from a CSV file and update the record in the JSS
# The CSV file needs to be saved as a UNIX file with LF, not CR
# Version: 1.0
#
# A good portion of this script is re-purposed from the script posted in the following JAMF Nation article:
#
#  https://jamfnation.jamfsoftware.com/discussion.html?id=13118#respond
#

jssAPIUsername="<apiuser>"
jssAPIPassword="<apipassword>"
jssAddress="https://your.jss.com:8443"
file="<path-to-csv-file>"

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
	leaseExpires=`echo "$line" | awk -F , '{print $2}'`
	
	echo "Attempting to update lease data for $serialNumber"

	# use serialNumber to locate the ID of the comptuer
	### Add some logic to test for an empty set coming back from serial number check.
	myOutput=`curl -su ${jssAPIUsername}:${jssAPIPassword} -X GET ${jssAddress}/JSSResource/computers/serialnumber/$serialNumber`
	myResult=`echo $myOutput | xpath /computer/general/id[1] | awk -F'>|<' '/id/{print $3}'`
	myID=`echo $myResult | tail -1`
	
	echo $serialNumber " " $myID " " $leaseExpires
	apiData="<computer><purchasing><lease_expires>$leaseExpires</lease_expires></purchasing></computer>"
	output=`curl -sS -k -i -u ${jssAPIUsername}:${jssAPIPassword} -X PUT -H "Content-Type: text/xml" -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>$apiData" ${jssAddress}/JSSResource/computers/id/$myID`

	echo $output
	#Error Checking
	error=""
	error=`echo $output | grep "Conflict"`
	if [[ $error != "" ]]; then
		duplicates+=($serialnumber)
	fi
	#Increment the ID variable for the next user
	id=$((id+1))
done

echo "The following computers could not be created:"
printf -- '%s\n' "${duplicates[@]}"

exit 0

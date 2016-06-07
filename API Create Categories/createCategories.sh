#!/bin/bash

# Name: createCategories.sh
# Date: 7 June 2016
# Author: Steve Wood (swood@integer.com) 
# Purpose: used to read in a list of categories from a CSV file and create them in the JSS
# 
# **** The CSV file needs to be saved as a UNIX file with LF, not CR ****
# Version: 1.0
#
# A good portion of this script is re-purposed from the script posted in the following JAMF Nation article:
#
#  https://jamfnation.jamfsoftware.com/discussion.html?id=13118#respond
#
# Usage: createCategories.sh apiuser apipass path-to-csv-file

# Variables
args=("$@")
jssAPIUsername="${args[0]}"
jssAPIPassword="${args[1]}"
jssAddress="https://your.jss.com:8443"  # <-- make sure to put your JSS address here
file="${args[2]}"

#Verify we can read the file
data=`cat $file`
if [[ "$data" == "" ]]; then
	echo "Unable to read the file path specified"
	echo "Ensure there are no spaces and that the path is correct"
	exit 1
fi

#Find how many categories to import
catqty=`awk -F, 'END {printf "%s\n", NR}' $file`
echo "Category Qty = " $catqty
#Set a counter for the loop
counter="0"

duplicates=[]

#Loop through the CSV and submit data to the API
while [ $counter -lt $catqty ]
do
	counter=$[$counter+1]
	line=`echo "$data" | head -n $counter | tail -n 1`
	category=`echo "$line" | awk -F , '{print $1}'`
	
	echo "Attempting to add category named $category"

	apiData="<category><name>$category</name><priority>5</priority></category>" # <-- you can edit priority to what you want
	output=`curl -sS -k -i -u ${jssAPIUsername}:${jssAPIPassword} -X POST -H "Content-Type: text/xml" -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>$apiData" ${jssAddress}/JSSResource/categories/id/0`

	echo $output
	#Error Checking
	error=""
	error=`echo $output | grep "Conflict"`
	if [[ $error != "" ]]; then
		duplicates+=($category)
	fi

done

echo "The following categories could not be created:"
printf -- '%s\n' "${duplicates[@]}"

exit 0

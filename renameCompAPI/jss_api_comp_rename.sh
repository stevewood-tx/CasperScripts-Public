#!/bin/bash

# Name: jss_api_comp_rename.sh
# Date: 27 Oct 2015
# Author: Steve Wood (swood@integer.com)
# Purpose: utilize the JSS API to grab the building name of a machine
# and re-name the machine based on the building name.

### Variables
apiuser="$4"
apipass="$5"
jssAddress="$6" # use format https://jss.name.com:8443

# thanks to Rich Trouton (@rtrouton) for the following code
CheckBinary (){

# Identify location of jamf binary.

jamf_binary=`/usr/bin/which jamf`

 if [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ ! -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/sbin/jamf"
 elif [[ "$jamf_binary" == "" ]] && [[ ! -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/local/bin/jamf"
 elif [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/local/bin/jamf"
 fi
}

function readBuilding {

	output=`curl -sS -k -u ${apiuser}:${apipass} -X GET ${jssAddress}/JSSResource/computers/serialnumber/$serNum/subset/location`
	building=`echo $output | xpath /computer/location/building | sed 's/<building>//g' | sed 's/<[\/&]building>//g'`
	
}

# grab the serial number so we can query the JSS
serNum=$(ioreg -l | grep IOPlatformSerialNumber | awk '{print $4}'| sed 's/"//g')

# check where the JAMF binary is - this is a fix based on SIP in 10.11 El Capitan
CheckBinary

# using serial number query JSS for building
readBuilding $serNum

# use case stmt to rename based on building name
# change the Building1, Building2, etc to the names you need
# escape with single quotes if building name has spaces

case $building in
	Building1 )
		
	# set your rename criteria using the setComputerName verb for the jamf binary
	# you can use jamf help setComputerName from the command line to determine the switches.
	# Duplicate the building and re-name if you need more buidings in the case statement
	
		$jamf_binary setComputerName setComputerName <your criteria>
		
		;;
		
	Building2 )

		$jamf_binary setComputerName setComputerName <your criteria>
		
		;;
		
	esac
	
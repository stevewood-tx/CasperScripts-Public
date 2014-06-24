#!/bin/sh

# Name:  moveDomains.sh
# Date:  28 May 2014 v1.0
# Updated: 18 Jun 2014 v1.1
# Author:  Steve Wood (swood@integer.com)
# Purpose:  used to move users from one AD domain to a new one, or from OD to AD
# Updates:  v1.1 - set GroupID to static
#	- v1.1 - including message to users using jamfhelper
#			- adding code to check for domain membership
# Prequisites:  You'll need a policy in your JSS 

# Globals & Logging	
LOGPATH='<WHERE YOU STORE LOGS>'  # change this line to point to your local logging directory
if [[ ! -d "$LOGPATH" ]]; then
	mkdir $LOGPATH
fi
set -xv; exec 1> $LOGPATH/movedomainslog.txt 2>&1  # you can name the log file what you want
version=1.1
oldAD='<OLD AD DOMAIN>'
currentAD=`dsconfigad -show | grep -i "active directory domain" | awk '{ print $5 }'`

# let the user know what we are doing

banner=`/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -title "Moving Domains" -heading "Moving Domains Header" -description "We are moving your user account to the new authentication domain.  When we are completed, and your computer restarts, you will be able to login to your computer with the same password you use for Timebomb.  In fact, once this is completed you will use the same password for logging into your machine, logging onto the server, Timebomb, VPN, and Google." -icon <PATH-TO-YOUR-ICON> -button1 "Proceed" -button2 "Not Now" -defaultButton 1 -cancelButton 2 -timeout 60 -countdown` 

if [[ $banner == "2" ]]; then
	
	echo "User canceled the move."
	exit 1
	
fi

# Grab current user name
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`

##### if you do not have OD deployed you can remove the follwing lines
# unbind from LDAP
# sinc there is no easy way to determine if bound to OD, we will just run against our OD for good measure

dsconfigldap -r <YOUR OD DOMAIN>
#####

# unbind from AD
# check to see if we are bound to our current AD or not.  If not we can skip this

if [[ "$currentAD" = "$oldAD" ]]; then
	
	# remove the config for our old AD
	# you need a user in your AD that has the rights to remove computers from the domain

	dsconfigad -remove $oldAD -user <networkuser> -pass <networkuserpass>   

fi

# remove the local user from the machine so we get the proper UID assigned in dscl
dscl . delete /Users/$loggedInUser

# bind to new AD
# using a JAMF policy to bind to the new AD

jamf policy -id <policynumber> # can also use a custom trigger for the policy

# reset permissions
### some of the code below is courtesy of Ben Toms (@macmule)

###
# Get the Active Directory Node Name
###
adNodeName=`dscl /Search read /Groups/Domain\ Users | awk '/^AppleMetaNodeLocation:/,/^AppleMetaRecordName:/' | head -2 | tail -1 | cut -c 2-`

###
# Get the Domain Users groups Numeric ID
###

domainUsersPrimaryGroupID=`dscl /Search read /Groups/Domain\ Users | grep PrimaryGroupID | awk '{ print $2}'`

accountUniqueID=`dscl "$adNodeName" -read /Users/$loggedInUser 2>/dev/null | grep UniqueID | awk '{ print $2}'`


chown -R $accountUniqueID:$domainUsersPrimaryGroupID /Users/$loggedInUser

# restart the computer when done
# to make sure everything is working properly we will restart

shutdown -r now

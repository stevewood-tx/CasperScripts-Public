#!/bin/sh

# Name:  moveDomains.sh
# Date:  28 May 2014 v1.0
# Updated: 18 Jun 2014 v1.1
# Author:  Steve Wood (swood@integer.com)
# Purpose:  used to move users from one AD domain to a new one, or from OD to AD
# Updates:  v1.1 - set GroupID to static
#	- v1.1 - including message to users using jamfhelper
#			- adding code to check for domain membership
#			- adding logic for FileVault encrypted drives
#	- v1.2 - use of createmobileaccount to get around FileVault
#
# Prerequisites - when adding this to the JSS, make sure to configure Parameter 4 for the local admin user
# 					and Parameter 5 as the local admin user password to add the user to FileVault.  Need
#					cocoaDialog installed on the local system.
#
# NOTE: you may want to turn off logging (comment out 5 lines under #Globals & Loging) so that no passwords
# are captured.

# Globals & Logging	
LOGPATH='<WHERE YOU STORE LOGS>'  # change this line to point to your local logging directory
if [[ ! -d "$LOGPATH" ]]; then
	mkdir $LOGPATH
fi
set -xv; exec 1> $LOGPATH/movedomainslog.txt 2>&1  # you can name the log file what you want
version=1.2
oldAD='<OLD AD DOMAIN>'  # set this to your old AD domain name
newAD='<NEW AD DOMAIN>'  # set this to the new AD domain name
currentAD=`dsconfigad -show | grep -i "active directory domain" | awk '{ print $5 }'`
CD="/private/var/inte/bin/cocoaDialog.app/Contents/MacOS/cocoaDialog"  ####  set this to the location of cocoaDialog on your systems
osVersion=`sw_vers -productVersion | cut -d. -f1,2`
adminEmail='YOUREMAIL@YOURDOMAIN.COM'  ## enter an email address to receive notification of failure at

## Because of FileVault, if a system is encrypted it has to be a 10.8 or above machine

ENCRYPTIONEXTENTS=`diskutil cs list | grep -E "$EGREP_STRING\Has Encrypted Extents" | sed -e's/\|//' | awk '{print $4}'`

if [[ "$ENCRYPTIONEXTENTS" = "Yes" ]]; then

	if [[ $osVersion = "10.7" ]]; then
		
		## If not 10.8 or above we cannot continue. Tell the user this.  Adjust the -description to what you need/want
		/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -title "Wrong OS Version" -heading "Wrong OS Deteced" -description "In order for us to move you to the new domain, you need to be on OS 10.8 or higher.  Please upgrade via Self Service to Mavericks (10.9) and then re-run the Move Domains item."
		exit 1
		
	fi
fi

# let the user know what we are doing
#### Change the dialog to what you want to tell your users

banner=`/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -title "Moving Domains" -heading "Moving Domains Header" -description "We are moving your user account to the new authentication domain.  When we are completed, your computer will restart and you can use your new account inforation." -icon <PATH-TO-YOUR-ICON> -button1 "Proceed" -button2 "Not Now" -defaultButton 1 -cancelButton 2 -timeout 60 -countdown` 

if [[ $banner == "2" ]]; then
	
	echo "User canceled the move."
	exit 1
	
fi

# Grab current user name
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`

## Grab the user's home folder location
userHome=`dscl . read /Users/$loggedInUser NFSHomeDirectory | awk '{ print $2 }'`

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
	# you can also set this to a parameter in the JSS and pass as a variable

	dsconfigad -remove $oldAD -user <networkuser> -pass <networkuserpass>   

fi

# remove the local user from the machine so we get the proper UID assigned in dscl
dscl . delete /Users/$loggedInUser

# bind to new AD
# using a JAMF policy to bind to the new AD

jamf policy -id <policynumber> # can also use a custom trigger for the policy

### verify that the move was successful
checkAD=`dsconfigad -show | grep -i "active directory domain" | awk '{ print $5 }'`

if [[ "$checkAD" != "$newAD" ]]; then
	
	echo "SOMETHING WENT WRONG AND WE ARE NOT BOUND"
	
	#####  SEND AN EMAIL TO THE ADMIN  #####
	message1="$loggedInUser attempted to run the moveDomain.sh script and it failed to bind to $newAD."
	echo -e "$message1" | mail -s "Move Domains Script Failure" $adminEmail
	exit 99
	
fi

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


### Check to see if FileVault is enabled.  If it is we will need to grab some info from the user
#### this section will get stored in the log file if left on and will store the end user's password and
#### the admin user's password in clear text.  If not testing, disable logging by commenting out lines
#### under the Globals & Logging section above.

if [[ "$ENCRYPTIONEXTENTS" = "Yes" ]]; then
	
	# now we need to add the new UID to FV2
	# Use cocoaDialog to get the current user's password
	userPassword=`$CD standard-inputbox --informative-text "Please enter your $newAD password:" --float`
	userPassword=`echo $userPassword | awk '{ print $2 }'`
	
	# create the plist file:
	echo '<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
	<key>Username</key>
	<string>'$4'</string>
	<key>Password</key>
	<string>'$5'</string>
	<key>AdditionalUsers</key>
	<array>
	    <dict>
	        <key>Username</key>
	        <string>'$loggedInUser'</string>
	        <key>Password</key>
	        <string>'$userPassword'</string>
	    </dict>
	</array>
	</dict>
	</plist>' > /tmp/fvenable.plist  ### you can place this file anywhere just adjust the fdesetup line below

## Testing using createmobileaccount

	/System/Library/CoreServices/ManagedClient.app/Contents/Resources/createmobileaccount -n $loggedInUser

	# now enable FileVault
	fdesetup add -i < /tmp/fvenable.plist
	
fi

### Restart the computer

shutdown -r now

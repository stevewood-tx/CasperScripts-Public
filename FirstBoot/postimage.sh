#!/bin/sh

###############################################################################
#
# Name: postimage.sh
# Version: 2.0
# Date:  08 July 2016
# 
# Author:  Steve Wood (swood@integer.com)
# Purpose:  first boot script to run as part of imaging process to configure
# systems.
# 
###############################################################################

## Set global variables

LOGPATH='/path/to/your/logs'
JSSURL='https://<yourjssurl>'
JSSCONTACTTIMEOUT=120 # amount of time to wait before timing out waiting for connection
LOGFILE=$/LOGPATH/deployment-$(date +%Y%m%d-%H%M).logging #re-name to whatever name you want
VERSION=10.11.5

## Setup logging
if [[ ! -d $LOGPATH ]]; then
    mkdir $LOGPATH
fi
set -xv; exec 1> $LOGFILE 2>&1

################################################################################
##
##  The below section of code was "borrowed" from Mike Morales' software update
##  script.  This script can be found in the following JAMF Nation posting:
##
##  https://jamfnation.jamfsoftware.com/discussion.html?id=5404#respond
##
##  And on his GitHub page here:  https://github.com/mm2270/CasperSuiteScripts/blob/master/selectable_SoftwareUpdate.sh
##
##  Thanks Mike for some great code.
##
################################################################################

## Block the user from being able to see our trickery
## Define the name and path to the LaunchAgent plist
PLIST="/Library/LaunchAgents/com.LockLoginScreen.plist"

## set the icon
swuIcon="<set to your ICON for use on lock screen if you want>"

## Define the text for the xml plist file
LAgentCore="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>Label</key>
	<string>com.LockLoginScreen</string>
	<key>RunAtLoad</key>
	<true/>
	<key>LimitLoadToSessionType</key>
	<string>LoginWindow</string>
	<key>ProgramArguments</key>
	<array>
		<string>/System/Library/CoreServices/RemoteManagement/AppleVNCServer.bundle/Contents/Support/LockScreen.app/Contents/MacOS/LockScreen</string>
		<string>-session</string>
		<string>256</string>
	</array>
</dict>
</plist>"

## Create the LaunchAgent file
echo "Creating the LockLoginScreen LaunchAgent..."
echo "$LAgentCore" > "$PLIST"

## Set the owner, group and permissions on the LaunchAgent plist
echo "Setting proper ownership and permissions on the LaunchAgent..."
chown root:wheel "$PLIST"
chmod 644 "$PLIST"

## Use SIPS to copy and convert the SWU icon to use as the LockScreen icon

## First, back up the original Lock.jpg image
echo "Backing up Lock.jpg image..."
mv /System/Library/CoreServices/RemoteManagement/AppleVNCServer.bundle/Contents/Support/LockScreen.app/Contents/Resources/Lock.jpg \
/System/Library/CoreServices/RemoteManagement/AppleVNCServer.bundle/Contents/Support/LockScreen.app/Contents/Resources/Lock.jpg.bak

## Now, copy and convert the SWU icns file into a new Lock.jpg file
## Note: We are converting it to a png to preserve transparency, but saving it with the .jpg extension so LockScreen.app will recognize it.
## Also resize the image to 400 x 400 pixels so its not so honkin' huge!
##echo "Creating SoftwareUpdate icon as png and converting to Lock.jpg..."
##sips -s format png "$swuIcon" --out /System/Library/CoreServices/RemoteManagement/AppleVNCServer.bundle/Contents/Support/LockScreen.app/Contents/Resources/Lock.jpg \
##--resampleWidth 400 --resampleHeight 400

cp $swuIcon /System/Library/CoreServices/RemoteManagement/AppleVNCServer.bundle/Contents/Support/LockScreen.app/Contents/Resources/Lock.jpg

## Now, kill/restart the loginwindow process to load the LaunchAgent
echo "Ready to lock screen. Restarting loginwindow process..."
kill -9 $(ps axc | awk '/loginwindow/{print $1}')

######################################################################################
######################################################################################
# 
# 		Tasks that do not require access to the JSS
# 
######################################################################################

####
# grab the OS version and Model, we'll need it later
####

modelName=`system_profiler SPHardwareDataType | awk -F': ' '/Model Name/{print $NF}'`

######################################################################################
# Dummy package with image date and computer Model
# - this can be used with an ExtensionAttribute to tell us when the machine was last imaged
######################################################################################
/bin/echo "Creating imaging receipt..."
/bin/date
TODAY=`date +"%Y-%m-%d"`
if [[ ! -d "/Library/Application Support/JAMF/Receipts" ]]; then
    mkdir /Library/Application\ Support/JAMF/Receipts
fi
touch /Library/Application\ Support/JAMF/Receipts/$modelName_Imaged_$TODAY.pkg

###############################################################################
#
#   S Y S T E M   P R E F E R E N C E S
#
# This section deals with system preference tweaks
#
###############################################################################
/bin/echo "Setting system preferences"
/bin/date

# Disable Time Machine's pop-up message whenever an external drive is plugged in

defaults write /Library/Preferences/com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

###########
# TIME
###########
# now set the time zone
/bin/echo "Setting time"
/bin/date
systemsetup -settimezone America/Chicago

# enable network time
systemsetup -setusingnetworktime on

# set the time server
systemsetup -setnetworktimeserver time.apple.com

### Enable Location Services to set time based on location

/bin/launchctl unload /System/Library/LaunchDaemons/com.apple.locationd.plist
uuid=`ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}'`
/usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd.$uuid \
	LocationServicesEnabled -int 1
/usr/sbin/chown -R _locationd:_locationd /var/db/locationd
/bin/launchctl load /System/Library/LaunchDaemons/com.apple.locationd.plist

# set time zone automatically using current location 
/usr/bin/defaults write /Library/Preferences/com.apple.timezone.auto Active -bool true

####

# disable the save window state at logout
/usr/bin/defaults write com.apple.loginwindow 'TALLogoutSavesState' -bool false
				
###########
# SSH
###########
# enable remote log in, ssh
/bin/echo "Setting ssh"
/bin/date
/usr/sbin/systemsetup -setremotelogin on

###########
#  AFP
###########

# enforce clear text passwords in AFP
/bin/echo "Setting AFP clear text"
/bin/date
/usr/bin/defaults write com.apple.AppleShareClient "afp_cleartext_allow" 0

# Turn off DS_Store file creation on network volumes
/bin/echo "Turn off DS_Store"
/bin/date
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.desktopservices \
	DSDontWriteNetworkStores true

# Turn off Gatekeeper
/bin/echo "Disable gatekeeper"
/bin/date
spctl --master-disable

### universal Access - enable access for assistive devices
## http://hints.macworld.com/article.php?story=20060203225241914
/bin/echo "Enable assistive devices"
/bin/date

/bin/echo -n 'a' | /usr/bin/sudo /usr/bin/tee /private/var/db/.AccessibilityAPIEnabled > /dev/null 2>&1 
/usr/bin/sudo /bin/chmod 444 /private/var/db/.AccessibilityAPIEnabled

### auto brightness adjustment off
/bin/echo "Disable auto brightness"
/bin/date
/usr/bin/defaults write com.apple.BezelServices 'dAuto' -bool false

### time machine off
/bin/echo "Disable Time Machine"
/bin/date
/usr/bin/defaults write com.apple.TimeMachine 'AutoBackup' -bool false
	
###  Expanded print dialog by default
# <http://hints.macworld.com/article.php?story=20071109163914940>
#
/bin/echo "Expanded print dialog by default"
/bin/date
# expand the print window
defaults write /Library/Preferences/.GlobalPreferences PMPrintingExpandedStateForPrint2 -bool TRUE

##Turn off Natural Scrolling
/bin/echo "Turn off Natural Scrolling"
/bin/date
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/.GlobalPreferences.plist com.apple.swipescrolldirection -boolean FALSE

###########
#  Misc
###########

##########################################
#  Delete iLife folders
##########################################
/bin/echo "Deleting iLife Apps"
/bin/date

if [[ -d /Applications/GarageBand.app ]]; then
	
	rm -rf /Applications/GarageBand.app
	rm -rf /Applications/iMovie.app
	rm -rf /Applications/iPhoto.app

fi

##########################################
# /etc/authorization changes
##########################################

security authorizationdb write system.preferences allow
security authorizationdb write system.preferences.datetime allow
security authorizationdb write system.preferences.printing allow
security authorizationdb write system.preferences.energysaver allow
security authorizationdb write system.preferences.network allow 
security authorizationdb write system.services.systemconfiguration.network allow

# check for jamf binary
/bin/echo "Checking for JAMF binary"
/bin/date

 if [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ ! -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/sbin/jamf"
 elif [[ "$jamf_binary" == "" ]] && [[ ! -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/local/bin/jamf"
 elif [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
    jamf_binary="/usr/local/bin/jamf"
 fi

# rename computer so it will fall into scope for first boot policies
sernum=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')
scutil --set ComputerName "NEW-${sernum}"
scutil --set HostName "NEW-${sernum}"
scutil --set LocalHostName "NEW-${sernum}"

touch /Library/Application\ Support/JAMF/Receipts/firstboot.pkg
${jamf_binary} recon

## JSS Policies for installing software
## Duplicate each block for the number of policies you need to run at post imaging time
/bin/echo "Installing <change to name of software>"
/bin/date
${jamf_binary} policy -id 1 # MAKE SURE TO SET TO THE CORRECT POLICY ID #

## Install Apple Software Updates from Apple's servers
/bin/echo "Installing Apple SWU"
/bin/date
softwareupdate --clear-catalog
softwareupdate -iav

##########################################
# Remove user folders from /Users
##########################################

find /Users -mindepth 1 -type d -maxdepth 1 -not -name Shared -exec rm -rf {} \;

##Remove Apple's info files.
rm -R /System/Library/User\ Template/Non_localized/Downloads/About\ Downloads.lpdf
rm -R /System/Library/User\ Template/Non_localized/Documents/About\ Stacks.lpdf

## remove from FirstBoot Group
rm /Library/Application\ Support/JAMF/Receipts/firstboot.pkg
${jamf_binary} recon

##########################################
# Remove setup launchdaemon
##########################################

srm $PLIST # remove the lock screen plist
#### **** CHANGE TO YOUR LAUNCHDAEMON NAME
srm /Library/LaunchDaemons/com.yourcompany.postimage.plist

killall jamfHelper
shutdown -r now
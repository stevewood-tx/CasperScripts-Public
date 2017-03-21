#!/bin/sh

###############################################################################
#
# Name: firstboot_DEP.sh
# Version: 1.0
# Date:  25 May 2016
# 
# Author:  Steve Wood (swood@integer.com)
# Purpose:  first boot script to run as part of imaging process to configure
# systems.
# 
###############################################################################

## Set global variables

LOGPATH='/path/to/your/logs'
JSSURL='https://<yourjssurl>'
JSSCONTACTTIMEOUT=120
LOGFILE=/path/to/your/logs/deployment-$(date +%Y%m%d-%H%M).logging
VERSION=10.11.4

## Setup logging
mkdir $LOGPATH
set -xv; exec 1> $LOGFILE 2>&1

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

#
# add our hidden bin path to $PATH

/bin/echo "Adding PATH"
/bin/date
/bin/echo "/private/var/inte/bin" >> /etc/paths

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

##Kill Dock Fixup
rm -R /Library/Preferences/com.apple.dockfixup.plist

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
scutil --set ComputerName "NEW-${sernum}-DEP"
scutil --set HostName "NEW-${sernum}-DEP"
scutil --set LocalHostName "NEW-${sernum}-DEP"

mkdir /Library/Application\ Support/JAMF/Receipts
touch /Library/Application\ Support/JAMF/Receipts/firstboot.pkg
${jamf_binary} recon

## Copy File Path
/bin/echo "Installing Copy File Path"
/bin/date
${jamf_binary} policy -id 27

## Printer Drivers
/bin/echo "Installing Printer Drivers"
/bin/date
${jamf_binary} policy -id 28

## Web Browsers
/bin/echo "Installing Web Browsers"
/bin/date
${jamf_binary} policy -id 29

## Video Conferencing
/bin/echo "Installing Video Conferencing"
/bin/date
${jamf_binary} policy -id 30

## Video Plugins
/bin/echo "Installing Video Plugins"
/bin/date
${jamf_binary} policy -id 31

## Java
/bin/echo "Installing Java"
/bin/date
${jamf_binary} policy -id 33

## Office 2011
/bin/echo "Installing Office 2011"
/bin/date
${jamf_binary} policy -id 34

## Creative Cloud
/bin/echo "Installing Adobe CC"
/bin/date
${jamf_binary} policy -id 37

/bin/echo "Installing Apple SWU"
/bin/date
softwareupdate --clear-catalog
softwareupdate -iav

# delete the temp user used for DEP enrollment
dscl . delete /Users/<tempusername>
rm -rf /Users/<tempusername>

killall jamfHelper
shutdown -r now

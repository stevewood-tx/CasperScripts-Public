#!/bin/sh

###############################################################################
#
# Name: postimage_10.9.sh
# Version: 1.0
# Date:  03 December 2013
# Updated:  April 2014
# Author:  Steve Wood (swood@integer.com)
# Purpose:  first boot script to run as part of imaging process to configure
# systems.
# 
# Credit and thanks to the team at Oxford College
###############################################################################

## Set global variables

LOGPATH='/private/var/inte/logs'
JSSURL='https://jss.yourdomain.com:8443'
JSSCONTACTTIMEOUT=120
FIRSTRUN='/Library/Application\ Support/JAMF/FirstRun/Enroll/enroll.sh'
ENROLLLAUNCHDAEMON='/Library/LaunchDaemons/com.jamfsoftware.firstrun.enroll.plist'
LOGFILE=/private/var/inte/logs/deployment-$(date +%Y%m%d-%H%M).logging

## Setup logging
mkdir $LOGPATH
set -xv; exec 1> $LOGPATH/postimagelog.txt 2>&1
/usr/bin/say "Begining Post Image Script"


######################################################################################
# 
# 		Tasks that do not require access to the JSS
# 
######################################################################################

####
# grab the OS version and Model, we'll need it later
####

osVersion=`sw_vers -productVersion | cut -d. -f1,2`
modelName=`system_profiler SPHardwareDataType | awk -F': ' '/Model Name/{print $NF}'`
shortModel=`system_profiler SPHardwareDataType | grep 'Model Name:' | awk '{ print $3 }'`

######################################################################################
# Dummy package with image date and computer Model
######################################################################################
/bin/echo "Creating imaging receipt..."
/bin/date
TODAY=`date +"%Y-%m-%d"`
touch /Library/Application\ Support/JAMF/Receipts/$modelName_Imaged_$TODAY.pkg

####
# grab the wi-fi port number for 10.7 and up, and AirPort port for 10.6 and below
####
/bin/echo "Getting wi-fi interface"
/bin/date

WIFI=$(/usr/sbin/networksetup -listnetworkserviceorder | /usr/bin/awk -F'\\) ' '/Wi-Fi/ { printf $2 }')
wifiPort=`networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/,/Ethernet/' | awk 'NR==2' | cut -d " " -f 2`

## turn on wi-fi and connect to network

networksetup -setairportpower $wifiPort on
networksetup -addpreferredwirelessnetworkatindex en0 <networkname> 1 WPA2 <networkpassword>


###############################################################################
#
#   S Y S T E M   P R E F E R E N C E S
#
# This section deals with system preference tweaks
#
###############################################################################
/bin/echo "Setting system preferences"
/bin/date

# now Activate Remote Desktop Sharing, enable access privileges for the users, grant full privileges for the users, restart arduser Agent and Menu extra:

/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -users <adminuser> -privs -all -restart -agent -menu

#
# Enable AirDrop over on all machines on all interfaces
#

/bin/echo "Enabling AirDrop..."
/bin/date
/usr/bin/defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1 

# Disable Time Machine's pop-up message whenever an external drive is plugged in

defaults write /Library/Preferences/com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

## Show on desktop
/bin/echo "Show on desktop"
/bin/date
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true

# Set default  screensaver settings

mkdir /System/Library/User\ Template/English.lproj/Library/Preferences/ByHost


# Disabling screensaver password requirement by commenting out this line - can be re-enabled later.
#
# defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver.$MAC_UUID "askForPassword" -int 1
#

defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver.$MAC_UUID "idleTime" -int 900

defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver.$MAC_UUID "moduleName" -string "Flurry"

defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver.$MAC_UUID "modulePath" -string "/System/Library/Screen Savers/Flurry.saver"

##########################################
# Power Management
##########################################
/bin/echo "Setting power management"
/bin/date

# Detects if this Mac is a laptop or not by checking the model ID for the word "Book" in the name.

if [[ $shortModel == "MacBook" ]]; then
	pmset -b sleep 15 disksleep 10 displaysleep 5 halfdim 1
	pmset -c sleep 0 disksleep 0 displaysleep 30 halfdim 1
else	
	pmset sleep 0 disksleep 0 displaysleep 30 halfdim 1
fi

##########################################
#  Scroll Bars
##########################################
/bin/echo "Disabling Scroll Bars"
/bin/date

# Sets the "Show scroll bars" setting (in System Preferences: General)
# to "Always" in your Mac's default user template and for all existing users.
# Code adapted from DeployStudio's rc130 ds_finalize script, where it's 
# disabling the iCloud and gestures demos

# Checks the system default user template for the presence of 
# the Library/Preferences directory. If the directory is not found, 
# it is created and then the "Show scroll bars" setting (in System 
# Preferences: General) is set to "Always".

for USER_TEMPLATE in "/System/Library/User Template"/*
  do
     if [ ! -d "${USER_TEMPLATE}"/Library/Preferences ]
      then
        mkdir -p "${USER_TEMPLATE}"/Library/Preferences
     fi
     if [ ! -d "${USER_TEMPLATE}"/Library/Preferences/ByHost ]
      then
        mkdir -p "${USER_TEMPLATE}"/Library/Preferences/ByHost
     fi
     if [ -d "${USER_TEMPLATE}"/Library/Preferences/ByHost ]
      then
        defaults write "${USER_TEMPLATE}"/Library/Preferences/.GlobalPreferences AppleShowScrollBars -string Always
     fi
  done

# Checks the existing user folders in /Users for the presence of
# the Library/Preferences directory. If the directory is not found, 
# it is created and then the "Show scroll bars" setting (in System 
# Preferences: General) is set to "Always".

for USER_HOME in /Users/*
  do
    USER_UID=`basename "${USER_HOME}"`
    if [ ! "${USER_UID}" = "Shared" ] 
     then 
      if [ ! -d "${USER_HOME}"/Library/Preferences ]
       then
        mkdir -p "${USER_HOME}"/Library/Preferences
        chown "${USER_UID}" "${USER_HOME}"/Library
        chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
      fi
      if [ ! -d "${USER_HOME}"/Library/Preferences/ByHost ]
       then
        mkdir -p "${USER_HOME}"/Library/Preferences/ByHost
        chown "${USER_UID}" "${USER_HOME}"/Library
        chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
	chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/ByHost
      fi
      if [ -d "${USER_HOME}"/Library/Preferences/ByHost ]
       then
        defaults write "${USER_HOME}"/Library/Preferences/.GlobalPreferences AppleShowScrollBars -string Always
        chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/.GlobalPreferences.*
      fi
    fi
  done


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
/usr/bin/defaults write com.apple.AppleShareClient "afp_cleartext_allow" 1

# Turn off DS_Store file creation on network volumes
/bin/echo "Turn off DS_Store"
/bin/date
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.desktopservices DSDontWriteNetworkStores true

##########################################
# Login Window Customizations
##########################################

# allow click thru clock to see IP, Host Name, OS version
/bin/echo "Setting click thru clock on loginwindow"
/bin/date
defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Set the login window to name and password
/bin/echo "Setting loginwindow to name & password"
/bin/date
defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true

# Disable external accounts (i.e. accounts stored on drives other than the boot drive.)
/bin/echo "Disable external accounts"
/bin/date
defaults write /Library/Preferences/com.apple.loginwindow EnableExternalAccounts -bool false

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

##Disable Fast User Switching
/bin/echo "Disable Fast User Switching"
/bin/date
defaults write /Library/Preferences/.GlobalPreferences MultipleSessionEnabled -bool FALSE

##Turn off Natural Scrolling
/bin/echo "Turn off Natural Scrolling"
/bin/date
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/.GlobalPreferences.plist com.apple.swipescrolldirection -boolean FALSE

###########
#  Misc
###########

# Disables iCloud pop-up on first login for Macs

for USER_TEMPLATE in "/System/Library/User Template"/*
  do
    defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool TRUE
    defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
    defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion 10.8
  done


##Move the mini launcher to keep the icloud prompts from happening on new user setup
mv /System/Library/CoreServices/Setup\ Assistant.app/Contents/SharedSupport/MiniLauncher /System/Library/CoreServices/Setup\ Assistant.app/Contents/SharedSupport/MiniLauncher.backup

##Kill Dock Fixup
rm -R /Library/Preferences/com.apple.dockfixup.plist

### clean up JAMF's spotlight issues
###  this code thanks to Oxford University's Mac department
###   and Marko Jung
echo '--- cleaning up spotlight-disabling files and restarting indexing' 

TARGETFILES=("/.fseventsd/no_log" "/.metadata_never_index")
FIXNEEDED=0
RESULT=0

for FILE in "${TARGETFILES[@]}"; do
    if [ -e $FILE ]; then
        (( FIXNEEDED += 1 ))
        rm -f "$FILE" 
        (( RESULT += $? ))
    fi
done

if [ $FIXNEEDED -gt 0 ]; then
    echo 'Leftover files found. Cleanup required.' 

    if [ $RESULT -eq 0 ]; then
        echo 'Cleanup was successful.' 
    else
        echo 'There were problems cleaning up the files.' 
    fi

    # clear index and start Spotlight
    mdutil -E -i on /
else
    echo 'No cleanup required!' 
fi


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


######################################################################################
# 
# 		Tasks that do require access to the JSS
# 
######################################################################################

## Following block of code provided by Oxford University
# Copyright (C) 2013 University of Oxford IT Services
#    contact <nsms-mac@it.ox.ac.uk>
#    authors: Robin Miller, Aaron Wilson, Marko Jung

# Wait a certain number of minutes for JAMF enroll.sh script to complete. We do
# this because the enroll script put in place during the JAMF Imaging process
# uses the 'jamf manage' command which seems to often fail (with a 401
# (authentication) error), so we want to run 'jamf enroll' as well before we
# start to do things that require communication with the JSS. However, we also
# don't want to have a conflict if both happen to be run at the same time,
# which has occasionally happened. The enroll.sh script will try to run, but if
# it cannot contact the JSS, will wait 5 minutes and then try only once more,
# hence the 8 minute wait. 

WAITLIMIT=$(( 8 * 60 ))
WAITINCREMENT=30
echo "--- checking to see if JAMF enroll.sh is still running" >> $LOGFILE
while [ -e "$ENROLLLAUNCHDAEMON" ]; do
    if [ $WAITLIMIT -le 0 ]; then
        echo "Reached wait timeout of ${WAITLIMIT} seconds!" >> $LOGFILE
        break
    fi

    echo "Still not complete. Waiting another ${WAITINCREMENT} seconds..." >> $LOGFILE
    sleep $WAITINCREMENT 
    (( WAITLIMIT -= $WAITINCREMENT ))

done
echo 'Continuing now...' >> $LOGFILE


## check for the binary

# check for jamf binary
/bin/echo "Checking for JAMF binary"
/bin/date

jamfcheck="/usr/sbin/jamf"

# now check if it exists

if [[ -e $jamfcheck ]]

	then /bin/echo "Jamf binary present, continuing as planned..."
	
	else /bin/echo "Jamf binary is not present, we need to halt" 
	
	exit 55

fi

## Test the connection to the JSS
echo '--- testing jss connection'
loop_ctr=1
while ! curl --silent -o /dev/null --insecure ${JSSURL} ; do
    sleep 1;
    loop_ctr=$((loop_ctr+1))
    if [ $((loop_ctr % 10 )) -eq 0 ]; then
        echo "${loop_ctr} attempts"
    fi

    if [ ${loop_ctr} -eq ${JSSCONTACTTIMEOUT} ]; then
        echo "I'm bored ... giving up after ${loop_ctr} attempts"
		/bin/date
        exit 1
    fi
done	
echo "Contacted JSS (${loop_ctr} attempts)"

###########################################
# Flush all previous policy history
###########################################

/bin/echo "Flushing Policy History..."
/bin/date
/usr/sbin/jamf flushPolicyHistory -verbose

###########################################
# Touch a file and recon so machine is in FirstBoot SG
###########################################

touch /Library/Application\ Support/JAMF/Receipts/firstboot.pkg
jamf recon

##########################################
##########################################
#
# Install software and such via policy
#
##########################################
##########################################

##  Install iLife via Policy
/bin/echo "Installing iLife via Policy"
/bin/date
/usr/sbin/jamf policy -id 25

##  Adium
/bin/echo "Installing Adium via Policy"
/bin/date
/usr/sbin/jamf policy -id 26

## Copy File Path
/bin/echo "Installing Copy File Path"
/bin/date
/usr/sbin/jamf policy -id 27

## Printer Drivers
/bin/echo "Installing Printer Drivers"
/bin/date
/usr/sbin/jamf policy -id 28

## Web Browsers
/bin/echo "Installing Web Browsers"
/bin/date
/usr/sbin/jamf policy -id 29

## Video Conferencing
/bin/echo "Installing Video Conferencing"
/bin/date
/usr/sbin/jamf policy -id 30

## Video Plugins
/bin/echo "Installing Video Plugins"
/bin/date
/usr/sbin/jamf policy -id 31

## Integer Resources
/bin/echo "Installing Integer Resources"
/bin/date
/usr/sbin/jamf policy -id 32

## Java
/bin/echo "Installing Java"
/bin/date
/usr/sbin/jamf policy -id 33

## Office 2011
/bin/echo "Installing Office 2011"
/bin/date
/usr/sbin/jamf policy -id 34

## Creative Suite 6
/bin/echo "Installing CS6 Design Premium"
/bin/date
/usr/sbin/jamf policy -id 37

######### Software that requires some checks

##  CRASH PLAN FOR LAPTOPS
##  NEED TO CHECK FOR LAPTOPS AND LOAD CPPe

if [[ $shortModel == "MacBook" ]]; then
	
	/bin/echo "Installing CrashPlan"
	/bin/date
	/usr/sbin/jamf policy -id 36
	
fi

#####################################################
#
#  Install Apple SWU
#
#####################################################
/bin/echo "Installing Apple SWU"
/bin/date
/bin/rm /Library/Preferences/com.apple.SoftwareUpdate.plist
softwareupdate -iav

########## Done installing software #################

#####################################################
#
#  Clean up procedures
#
#####################################################

##########################################
# Remove user folders from /Users
##########################################

find /Users -mindepth 1 -type d -maxdepth 1 -not -name Shared -exec rm -rf {} \;

##Remove apples info files.
rm -R /System/Library/User\ Template/Non_localized/Downloads/About\ Downloads.lpdf
rm -R /System/Library/User\ Template/Non_localized/Documents/About\ Stacks.lpdf

####
# Now we must purge the system log to get rid of any passwords that may be in plain text
####

/bin/rm -rf /var/log/system.log

/bin/echo "purged logs"

## remove from FirstBoot Group
rm /Library/Application\ Support/JAMF/Receipts/firstboot.pkg
jamf recon

## Fix Permissions
/usr/sbin/jamf fixPermissions

##########################################
# Remove setup launchdaemon
##########################################

srm /Library/LaunchDaemons/com.integer.postimage109.plist

##########################################
# Reboot
##########################################

shutdown -r now



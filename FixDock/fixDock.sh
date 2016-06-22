#!/bin/sh

# Name: fixDock.sh
# Purpose:  to set the initial dock configuration for new users
# Date:  28 February 2014
# Updated: 22 Jun 2016
#	- changed how home folder is derived
# Author:  Steve Wood (swood@integer.com)

# Set Global Variables
# set the user folder to work on
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`
myUserHome=$(dscl . read /Users/$loggedInUser NFSHomeDirectory | awk '{print $NF}')

shortModel=`system_profiler SPHardwareDataType | grep 'Model Name:' | awk '{ print $3 }'`
# set the path to dockutil
du='<path to where you store dockutil>'

$du --remove all $myUserHome
$du --add "/Applications/Self Service.app" $myUserHome
$du --add "/Applications/Launchpad.app" $myUserHome
$du --add "/Applications/System Preferences.app" $myUserHome
$du --add "/Applications/Firefox.app" $myUserHome
$du --add "/Applications/Google Chrome.app" $myUserHome
$du --add "/Applications/Safari.app" $myUserHome
$du --add "/Applications/Microsoft Office 2011/Microsoft Excel.app" $myUserHome
$du --add "/Applications/Microsoft Office 2011/Microsoft Word.app" $myUserHome
$du --add "/Applications/Microsoft Office 2011/Microsoft PowerPoint.app" $myUserHome

if [[ -d "/Applications/Universal Type Client.app" ]]; then
    $du --add "/Applications/Universal Type Client.app" $myUserHome
fi

$du --add "/Applications/Adobe Illustrator CC 2014/Adobe Illustrator.app" $myUserHome
$du --add "/Applications/Adobe InDesign CC 2014/Adobe InDesign CC 2014.app" $myUserHome
$du --add "/Applications/Adobe Photoshop CC 2014/Adobe Photoshop CC 2014.app" $myUserHome
$du --add "/Applications/Adobe Acrobat XI Pro/Adobe Acrobat Pro.app" $myUserHome

if [[ $shortModel == "MacBook" ]]; then
    $du --add "/Applications/Cisco/Cisco AnyConnect Secure Mobility Client.app" $myUserHome
fi

$du --add '~/Downloads' --view grid --display folder $myUserHome
$du --add '/Applications' --view grid --display folder $myUserHome






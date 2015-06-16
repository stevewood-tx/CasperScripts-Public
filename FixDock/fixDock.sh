#!/bin/sh

# Name: fixDock.sh
# Purpose:  to set the initial dock configuration for new users
# Date:  28 February 2014
# Updated: 2 Apr 2015
#	- changed CS6 for CC
# Author:  Steve Wood (swood@integer.com)

# Set Global Variables
# set the user folder to work on
loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'`
myUser="/Users/${loggedInUser}"
#myUser="/Users/$3"

shortModel=`system_profiler SPHardwareDataType | grep 'Model Name:' | awk '{ print $3 }'`
#echo $myUser
# set the path to dockutil
du='<path to where you store dockutil>'

$du --remove all $myUser
$du --add "/Applications/Self Service.app" $myUser
$du --add "/Applications/Launchpad.app" $myUser
$du --add "/Applications/System Preferences.app" $myUser
$du --add "/Applications/Firefox.app" $myUser
$du --add "/Applications/Google Chrome.app" $myUser
$du --add "/Applications/Safari.app" $myUser
$du --add "/Applications/Microsoft Office 2011/Microsoft Excel.app" $myUser
$du --add "/Applications/Microsoft Office 2011/Microsoft Word.app" $myUser
$du --add "/Applications/Microsoft Office 2011/Microsoft PowerPoint.app" $myUser

if [[ -d "/Applications/Universal Type Client.app" ]]; then
    $du --add "/Applications/Universal Type Client.app" $myUser
fi

$du --add "/Applications/Adobe Illustrator CC 2014/Adobe Illustrator.app" $myUser
$du --add "/Applications/Adobe InDesign CC 2014/Adobe InDesign CC 2014.app" $myUser
$du --add "/Applications/Adobe Photoshop CC 2014/Adobe Photoshop CC 2014.app" $myUser
$du --add "/Applications/Adobe Acrobat XI Pro/Adobe Acrobat Pro.app" $myUser

if [[ $shortModel == "MacBook" ]]; then
    $du --add "/Applications/Cisco/Cisco AnyConnect Secure Mobility Client.app" $myUser
fi

$du --add '~/Downloads' --view grid --display folder $myUser
$du --add '/Applications' --view grid --display folder $myUser






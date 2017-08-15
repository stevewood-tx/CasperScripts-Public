#!/bin/bash

# Name: silverlightVersionPlist.sh
# Date: 15 Aug 2017
# Author: Steve Wood (steve.wood@omnicomgroup.com)
# Purpose: grabs the Silverlight version and updates a plist

plistPath='/path/to/plist/com.contoso.swversions.plist'

SilverlightVersion=""
if [[ -f /Library/Internet\ Plug-Ins/Silverlight.plugin/Contents/Info.plist ]]; then

	SilverlightVersion=$(defaults read /Library/Internet\ Plug-Ins/Silverlight.plugin/Contents/Info.plist CFBundleShortVersionString)
	defaults write ${plistPath} SilverlightVersion -string ${SilverlightVersion}

else

	defaults write ${plistPath} SilverlightVersion -string "Not Installed"
	
fi

exit 0
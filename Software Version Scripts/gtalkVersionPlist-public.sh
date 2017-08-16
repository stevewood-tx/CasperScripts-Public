#!/bin/bash

# Name: gtalkVersionPlist-public.sh
# Date: 15 Aug 2017
# Author: Steve Wood (steve.wood@omnicomgroup.com)
# Purpose: checks the version of Google Talk

plistPath='/path/to/plist/com.contoso.swversions.plist'

if [[ -d "/Library/Internet Plug-Ins/googletalkbrowserplugin.plugin" ]]; then

	gtalkVersion=`defaults read /Library/Internet\ Plug-Ins/googletalkbrowserplugin.plugin/Contents/Info CFBundleShortVersionString`
	defaults write ${plistPath} GTalkVersion -string ${gtalkVersion}
	
else
	
	defaults write ${plistPath} GTalkVersion -string "Not Installed"
	
fi


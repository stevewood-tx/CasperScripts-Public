#!/bin/bash

# Name: oracleVersionPlist.sh
# Date: 15 Aug 2017
# Author: Steve Wood (steve.wood@omnicomgroup.com)
# Purpose: checks the version of Java that is installed and writes
# to a plist to be read later by an Extension Attribute
#
# Parts of this script by Richt Trouton:
# https://github.com/rtrouton/rtrouton_scripts/blob/master/rtrouton_scripts/install_latest_oracle_java_8/install_latest_oracle_java_8.sh

plistPath='/path/to/plist/com.contoso.swversions.plist'
# check if Java is installed

if [[ -d "/Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin" ]]; then

	OracleUpdateXML="https://javadl-esd-secure.oracle.com/update/mac/au-1.8.0_20.xml"

	# Use the XML address defined in the OracleUpdateXML variable to query Oracle via curl 
	# for the complete address of the latest Oracle Java 8 installer disk image.

	currVersion=`/usr/bin/curl --silent $OracleUpdateXML | grep "sparkle:version" | cut -d '"' -f2`

	#check if installed version is same as current version on web site
	instVersion=$(defaults read /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Info.plist CFBundleVersion)

	if [[ $instVersion == $currVersion ]]; then

		#echo "<result>Latest</result>"
		defaults write ${plistPath} JavaVersion -string "Latest"

	else

		#echo "<result>Old</result>"
		defaults write ${plistPath} JavaVersion -string "Old"
	fi

else

    #echo "<result>Java Not Installed</result>"
	defaults write ${plistPath} JavaVersion -string "Not Installed"
    
fi
exit 0
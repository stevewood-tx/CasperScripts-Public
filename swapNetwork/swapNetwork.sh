#!/bin/bash

# Name:  swapNetwork.sh
# Date:
# Purpose:  disable the wi-fi port when ethernet is plugged in
# Original JAMF Nation post:  https://jamfnation.jamfsoftware.com/discussion.html?id=1441#respond
# Credit to Jonathan Synowiec for this
# Use in conjunction with a LaunchDaemon
# Version: 2.0
# Updated 29 Feb 2016 - updated to check for jamf binary location due to OS X 10.11 changes

if [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ ! -e "/usr/local/bin/jamf" ]]; then
   jamf_binary="/usr/sbin/jamf"
elif [[ "$jamf_binary" == "" ]] && [[ ! -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
   jamf_binary="/usr/local/bin/jamf"
elif [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
   jamf_binary="/usr/local/bin/jamf"
fi

##
# Define wireless interface "en" label.
wifiInterface=$(networksetup -listallhardwareports | grep 'Wi-Fi' -A1 | grep -o en.)
##
# Define wireless interface active status.
wifiStatus=$(ifconfig "${wifiInterface}" | grep 'status' | awk '{ print $2 }')
##
# Define wireless interface power status
wifiPower=$(networksetup -getairportpower "${wifiInterface}" | awk '{ print $4 }')
##
# Define non-wireless interface "en" labels.
ethernetInterface=$(networksetup -listallhardwareports | grep 'en' | grep -v "${wifiInterface}" | grep -o en.)
##
# Define non-wireless IP status.
ethernetIP=$(for i1 in ${ethernetInterface};do
  echo $(ifconfig "${i1}" | grep 'inet' | grep -v '127.0.|169.254.' | awk '{ print $2 }')
done)
##
# Disable active wireless interface if non-wireless interface connected.
if [[ "${ethernetIP}" && "${wifiStatus}" = "active" ]] || [[ "${ethernetIP}" && "${wifiPower}" = "On" ]]; then
  networksetup -setairportpower "${wifiInterface}" off
  touch /var/tmp/wifiDisabled; fi
##
# Enable inactive wireless interface if previously disabled by daemon.
if [[ "${ethernetIP}" = "" && "${wifiStatus}" = "inactive" ]] || [[ "${ethernetIP}" = "" && "${wifiPower}" = "Off" ]]; then
  if [[ -f "/var/tmp/wifiDisabled" ]]; then
    rm -f /var/tmp/wifiDisabled
    networksetup -setairportpower "${wifiInterface}" on; fi
fi

## update the JSS
checkjss=`${$jamf_binary} checkJSSConnection -retry 0 | grep "The JSS is available"`

if [ "$checkjss" == "The JSS is available." ]; then
	${$jamf_binary} log
fi

##
# Sleep to prevent launchd interpreting as a crashed process.
sleep 10
exit 0
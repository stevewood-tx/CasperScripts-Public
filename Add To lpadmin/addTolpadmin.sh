#!/bin/sh

# Name: addTolpadmin
# Date: 20 Mar 2017
# Author: Steve Wood (steve.wood@omnicomgroup.com)
# Purpose: used to add users to the lpadmin group after checking if they are already members

# Logging - thanks to Dan Snelson (@dan.snelson on Jamf Nation)
logFile="/private/var/logs/addTolpadmin.log"

# Check for / create logFile
if [ ! -f "${logFile}" ]; then
    # logFile not found; Create logFile
    /usr/bin/touch "${logFile}"
fi

function ScriptLog() { # Re-direct logging to the log file ...

    exec 3>&1 4>&2        # Save standard output and standard error
    exec 1>>"${logFile}"    # Redirect standard output to logFile
    exec 2>>"${logFile}"    # Redirect standard error to logFile

    NOW=`date +%Y-%m-%d\ %H:%M:%S`    
    /bin/echo "${NOW}" " ${1}" >> ${logFile}

}

function checkMembership() { # check if the user is a member already

    groupMembers+=($(dscl . read /Groups/lpadmin GroupMembership 2>/dev/null | tr ' ' '\n' | sed '1d'))
    
    for members in "${groupMembers[@]}"
    do
        if [[ ${members} == ${loggedInUser} ]]; then
            
            echo "Already in the group"
            exit 0
            
        fi
        
    done
    dseditgroup -o edit -a ${loggedInUser} -t user _lpadmin
}

# change logging
ScriptLog

# grab the logged in user
loggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`

# check if member of lpadmin and if not, add
checkMembership
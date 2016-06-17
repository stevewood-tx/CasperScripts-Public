#!/usr/bin/env python
'''
Date: 17 Jun 2016
Author: Steve Wood (swood@integer.com)
Purpose: Use the JSS API to re-add Fiery printers after updating the Fiery drivers

Be certain to change the API user name and password, along with the JSS URL.

Also, change the policy ID #s for the printer add scripts.

This is run as an After script to removing the Fiery drivers and then adding the new ones.
You need to have JSS Policies to add the printers back without re-installing the drivers during the policy run.

Just add more "elif" statements for the printers you have.
'''

import urllib
import subprocess
import os.path
import xml.etree.ElementTree as ET

# add your api user and password, and change the jss address
jssAPIuser = 'apiuser'
jssAPIpass = 'apipass'
jssURL = 'https://' + jssAPIuser + ':' + jssAPIpass + \
    '@your.jss.com:8443'

name = list()

# determine the path to the JAMF binary
def jamf_check():
    if os.path.exists('/usr/sbin/jamf'):
        jamfbin = '/usr/sbin/jamf'
    elif os.path.exists('/usr/local/bin/jamf'):
        jamfbin = '/usr/local/bin/jamf'
    return jamfbin


serial = subprocess.Popen("system_profiler SPHardwareDataType |grep -v tray | awk '/Serial/ {print $4}'", shell=True, stdout=subprocess.PIPE).communicate()[0].strip()
jamfbinary = jamf_check()
url = jssURL + '/JSSResource/computers/serialnumber/' + serial + '/subset/Hardware'
uh = urllib.urlopen(url)
data = uh.read()
tree = ET.fromstring(data)
# use XPath syntax to locate the printers mapped to the computer
for printer in tree.findall("./hardware/mapped_printers/printer"):
    #load the names into a list for later use
    name.append(printer.find('name').text)
# iterate through the list of printer names and call the appropriate jamf policy to add the printer
for item in name:
    if item == "PrinterName1":
        # run the associated policy to install the printer
        addCopyThat = subprocess.call(jamfbinary + " policy -id #", shell=True)
    elif item == "PrinterName2":
        # run the associated policy to install the printer
        addCopyThat = subprocess.call(jamfbinary + " policy -id #", shell=True)
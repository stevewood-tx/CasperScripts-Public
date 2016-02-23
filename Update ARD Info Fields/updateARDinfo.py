#!/usr/bin/env python

# Name: updateARDinfo.py
# Date: 23 February 2016
# Purpose: used to pull location data out of the JSS and use it to update
# the ARD fields on a computer.

# This will pull Real Name, User name, and Building from JSS via API. Change the
# variables to pull different information and push to the ARD Fields.

import urllib
import subprocess
import os.path
import xml.etree.ElementTree as ET


jssAPIuser = 'apiuser'
jssAPIpass = 'apipass'
jssURL = 'https://' + jssAPIuser + ':' + jssAPIpass + \
    '@jss.server.com:8443'


def jamf_check():
    if os.path.exists('/usr/sbin/jamf'):
        jamfbin = '/usr/sbin/jamf'
    elif os.path.exists('/usr/local/bin/jamf'):
        jamfbin = '/usr/local/bin/jamf'
    return jamfbin


serial = subprocess.Popen("system_profiler SPHardwareDataType |grep -v tray \
    | awk '/Serial/ {print $4}'", shell=True, stdout=subprocess.PIPE).\
    communicate()[0].strip()

url = jssURL + \
    '/JSSResource/computers/serialnumber/' + serial
uh = urllib.urlopen(url)
data = uh.read()
tree = ET.fromstring(data)
location = tree.findall('location')
full_name = location[0].find('real_name').text
user_name = location[0].find('username').text
building = location[0].find('building').text

updateARD = subprocess.check_output([jamf_check(), 'setARDFields', '-1', full_name, '-2', user_name, '-3', building])

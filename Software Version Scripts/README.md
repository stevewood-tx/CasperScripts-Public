These scripts can be used to grab software version information and store in a local plist file to be read later by an Extension Attribute.

The reason we might want to use this method rather than grabbing the info in an EA, is to reduce the amount of time
it takes for a computer to recon. Each time a computer updates inventory the EAs run. If you have a lot of EAs grabbing version
information, this can lengthen the amount of time the inventory update takes.

Create a policy that runs on whatever frequency you want, Once Per Day, Once Per Week, Once Per Month, and attach
these scripts to that policy. 

Now create your Extension Attributes for each one and use the 'defaults' command to read the values out of the plist:

SilverlightVersion=`defaults read /path/to/your/plist SilverlightVersion`

You can do the same for the others. This is further documented in my blog post here:

http://www.geekygordo.com/blog/2016/7/13/collecting-data-using-plist-files

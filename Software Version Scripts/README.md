These scripts can be used to grab software version information and store in a local plist file to be read later by an Extension Attribute.

The reason we might want to use this method rather than grabbing the info in an EA, is to reduce the amount of time
it takes for a computer to recon. Each time a computer updates inventory the EAs run. If you have a lot of EAs grabbing version
information, this can lengthen the amount of time the inventory update takes.

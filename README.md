```
[fkabell@localhost ~]$ /usr/local/bin/rmdevice.sh
usage: rmdevice.sh [-l|-r] [-d DAYS] [-f FILE]
List or remove Merakis that have been offline for >= DAYS days.
-l or -r AND -d are required arguments.

-d      Specify number of days.
-f      Text file containing Meraki serial numbers to exclude.
-l      Output CSV file listing offline Merakis.
-r      Remove offline Merakis from network.
```

List and remove (not unclaim) Meraki devices from their corresponding Meraki networks. Specify a number of days, and any Meraki that has been offline for at least that amount of time is listed or removed.<br>

Before the script (`rmdevice.sh`) may be used, you must:

* verify that `curl` and `jq` are installed,
* generate and store your Meraki API key,
* edit `organization_id.sh` to include your API key,
* run `organization_id.sh` to get your organization ID, and
* edit `rmdevice.sh` to include your API key and organization ID.

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

#!/bin/sh

# Depends on curl(1), jq(1), and GNU date(1) `-d' flag.

merakiapikey=''
merakiorganizationid=''

die() {
	printf '%s: %s\n' Fatal "$1" 2>&1
	fatal=1
}
_curl() {
	eval curl -sLH \"Authorization: Bearer $merakiapikey\" \
	    -H \'Content-Type: application/json\' \
	    "$merakiapiurl"/$@
}

merakiapiurl='https://api.meraki.com/api/v1'

set -e
# bash and ksh support pipefail, but dash does not.
set -o | grep pipefail >/dev/null 2>&1 && set -o pipefail

fatal=0

dflag=0
fflag=0
lflag=0
rflag=0
while getopts d:f:lr opt 2>/dev/null; do
	case "$opt" in
	    d)
	        dflag=1
	        days="$OPTARG"
	        ;;
	    f)
	        fflag=1
	        if [ -r "$OPTARG" ] && [ -s "$OPTARG" ]; then
	            excludefile="$OPTARG"
	        elif [ -r "$OPTARG" ]; then
	            die "$OPTARG is empty."
	        elif [ -s "$OPTARG" ]; then
	            die "$OPTARG is not readable."
	        else
	            die "$OPTARG does not exist."
	        fi
	        ;;
	    r)
	        rflag=1
	        ;;
	    l)
	        lflag=1
	        ;;
	esac
done

if { [ "$lflag" -eq 0 ] && [ "$rflag" -eq 0 ]; } || [ "$dflag" -eq 0 ]; then
	cat <<- EOF
	usage: $0 [-l|-r] [-d DAYS] [-f FILE]
	List or remove Merakis that have been offline for >= DAYS days.
	-l or -r AND -d are required arguments.

	-d	Specify number of days.
	-f	Text file containing Meraki serial numbers to exclude.
	-l	Output CSV file listing offline Merakis.
	-r	Remove offline Merakis from network.
	EOF
	fatal=1
fi

for cmd in curl jq; do
	if ! which "$cmd" >/dev/null 2>&1; then
	    die "$cmd not found."
	fi
done

if ! date --version 2>/dev/null | grep GNU >/dev/null; then
	die 'GNU date(1) not found.'
fi

for var in merakiapikey merakiorganizationid; do
	if eval [ -z "\$$var" ]; then
	    die "\$$var is empty."
	fi
done

# Meraki defines a device as
#	offline only if it has been offline for less than a week, or
#	dormant if either
#	    the device has been offline for a week or more, or
#	    the device has never been connected to the Meraki cloud.
if [ "$days" -lt 7 ] 2>/dev/null; then
	status='offline,dormant'
elif [ "$days" -ge 7 ] 2>/dev/null; then
	status='dormant'
else
	die "\`-d $days' is invalid."
fi

[ "$fatal" -eq 1 ] && exit 1

unixearlier="$(date -d "$days days ago" +%s)"

eval "$(_curl "organizations/$merakiorganizationid/devices/statuses?statuses[]={$status}" | \
	sed 's/\.[0-9]\{6\}Z/Z/g' | \
	jq --argjson unixearlier "$unixearlier" -r '.[] |
	select (.lastReportedAt | fromdateiso8601? < $unixearlier) |
	.serial |= gsub("-"; "") |
	"serials=\"$serials \(.serial)\"
	name\(.serial)=\"\(.name)\"
	mac\(.serial)=\"\(.mac)\"
	model\(.serial)=\"\(.model)\"
	networkid\(.serial)=\"\(.networkId)\"
	lastonline\(.serial)=\"\(.lastReportedAt)\""')"

for serial in $serials; do
	for var in name mac model networkid lastonline; do
	    eval $var=\$"$var$serial"
	    [ -z "$var" ] && continue 2
	done

	# Re-add hyphens that were stripped with jq(1) gsub().
	serial="$(printf "$serial" | sed -E 's/.{4}/&-/g; s/-$//')"
	grep "$serial" "$excludefile" >/dev/null 2>&1 && continue

	unixnow="$(date +%s)"
	unixonline="$(date -d "$lastonline" +%s)"
	unixago=$((unixnow - unixonline))
	# There are 86,400 seconds in one day.
	daysago=$((unixago / 86400))

	if [ "$lflag" -eq 1 ]; then
	    # A carriage return is required to upload the output into Microsoft Excel.
	    printf '%s\r\n' "$name,$serial,$mac,$model,$networkid,$daysago"
	elif [ "$rflag" -eq 1 ]; then
	    printf '%s\n' "Removing $model '$name' ($serial) from '$networkid'."
	    _curl "networks/$networkid/devices/remove" \
	        -d '"{ \"serial\": \"$serial\" }"'
	fi
done

exit 0

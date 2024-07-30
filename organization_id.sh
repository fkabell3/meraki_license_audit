#!/bin/sh

# Depends on curl(1) and jq(1).

# "Organization" -> "API & webhooks" -> "API keys and access" -> "Generate API Key"
merakiapikey=

die() {
	printf '%s: %s\n' Fatal "$1" 2>&1
	fatal=1
}

if [ -z "$merakiapikey" ]; then
	die "\$merakiapikey is empty."
fi

for cmd in curl jq; do
	if ! which "$cmd" >/dev/null 2>&1; then
	    die "$cmd not found."
	fi
done

[ "$fatal" -eq 1 ] && exit 1

curl -sLH "Authorization: Bearer $merakiapikey" \
	    -H 'Content-Type: application/json' \
	    https://api.meraki.com/api/v1/organizations | \
	    jq -r '.[] | "\(.name): \(.id)"'

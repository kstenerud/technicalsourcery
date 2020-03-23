#!/bin/sh

set -eu

HUGO_STAGE="${HUGO_STAGE:=draft}"
HUGO_CMD=/usr/local/bin/hugo

if [[ $HUGO_STAGE == 'draft' ]]; then
	HUGO_CMD="$HUGO_CMD server --bind=0.0.0.0 -D"
elif [[ $HUGO_STAGE == 'staging' ]]; then
	HUGO_CMD="$HUGO_CMD server --bind=0.0.0.0"
elif [[ $HUGO_STAGE != 'production' ]]; then
	echo "Error: $HUGO_STAGE: Unknown stage"
fi

$HUGO_CMD -w -s /src -d /output

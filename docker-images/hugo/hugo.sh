#!/bin/sh

HUGO_WATCH="${HUGO_WATCH:=false}"
HUGO_REFRESH_TIME="${HUGO_REFRESH_TIME:=-1}"
HUGO_DESTINATION="${HUGO_DESTINATION:=/output}"

HUGO=/usr/bin/hugo

while [ true ]
do
    if [[ $HUGO_WATCH != 'false' ]]; then
	    echo "Watching..."
        $HUGO server --watch=true --source="/src" --destination="$HUGO_DESTINATION" --bind="0.0.0.0" --port=80 --appendPort=false "$@" || exit 1
    else
	    echo "Building once..."
        $HUGO --source="/src" --destination="$HUGO_DESTINATION" "$@" || exit 1
    fi

    if [[ $HUGO_REFRESH_TIME == -1 ]]; then
        exit 0
    fi
    echo "Sleeping $HUGO_REFRESH_TIME seconds..."
    sleep $HUGO_REFRESH_TIME
done


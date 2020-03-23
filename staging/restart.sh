#!/bin/sh

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

"$SCRIPT_DIR/down.sh"
"$SCRIPT_DIR/up.sh"

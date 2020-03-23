#!/bin/sh

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

docker-compose -f "$SCRIPT_DIR/staging.yml" up -d

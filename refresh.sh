#!/bin/bash

set -eu

SCRIPT_DIR=$(dirname $(readlink -f "$0"))

cd "$SCRIPT_DIR"
git pull &&
docker restart ts-hugo

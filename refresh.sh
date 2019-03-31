#!/bin/bash

set -eu

SCRIPT_DIR=$(dirname $(readlink -f "$0"))

cd "$SCRIPT_DIR"
git pull &&
git submodule update --init --recursive &&
docker restart ts-hugo

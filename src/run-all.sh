#!/bin/zsh
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]-$0}")
BASE_DIR="$SCRIPT_DIR"/..

"$BASE_DIR"/src/run-ios.sh && "$BASE_DIR"/src/run-totem.sh

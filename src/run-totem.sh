#!/bin/zsh
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]-$0}")
BASE_DIR="$SCRIPT_DIR"/..
setopt XTRACE

if [ ! -f "$BASE_DIR"/"DOOM.WAD" ]; then
    echo "DOOM.WAD is missing."
    exit 1
fi

echo "Running totem."
pushd "$BASE_DIR"/totem
cargo run --release -p totem -- ../config/config.json
popd

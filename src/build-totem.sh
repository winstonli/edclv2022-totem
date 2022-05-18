#!/bin/zsh
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]-$0}")
BASE_DIR="$SCRIPT_DIR"/..
setopt XTRACE

pushd "$BASE_DIR"/totem
cargo build --release -p totem || {
    echo "cargo build failed: is Rust installed?" && exit 1
}
popd

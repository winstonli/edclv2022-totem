#!/bin/zsh
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]-$0}")
BASE_DIR="$SCRIPT_DIR"/..
setopt XTRACE

echo "Building Doom."
make -j 32 -C "$BASE_DIR"/totem-doom/doomgeneric || {
    echo "error while building totem-doom: is a C compiler installed? Try installing Xcode." && exit 1
}

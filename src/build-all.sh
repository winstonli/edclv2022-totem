#!/bin/zsh
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]-$0}")
BASE_DIR="$SCRIPT_DIR"/..

if [ ! -f "$BASE_DIR"/DOOM.WAD ]; then
    echo "DOOM.WAD is missing. Attempting to download the Shareware version."
    curl -o "$BASE_DIR"/DOOM.WAD https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad || {
        echo "error: DOOM.WAD download failed." && exit 1
    }
fi

"$BASE_DIR"/src/build-totem-ios.sh &&
"$BASE_DIR"/src/build-totem-doom.sh &&
"$BASE_DIR"/src/build-totem.sh

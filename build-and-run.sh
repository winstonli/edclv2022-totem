#!/bin/zsh

if [ -z "$(ls -A ./totem-doom)" ] || [ -z "$(ls -A ./totem-ios)" ] || [ -z "$(ls -A ./totem)" ]; then
    git submodule update --init --recursive
fi

./src/build-all.sh && ./src/run-all.sh

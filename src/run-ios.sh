#!/bin/zsh
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]-$0}")
BASE_DIR="$SCRIPT_DIR"/..
setopt XTRACE

if ! xcrun simctl list | grep "totem-phone"; then
    echo "Creating simulator phone."
    xcrun simctl create 'totem-phone' "iPhone 13 Pro" "iOS15.2" || {
        echo "error: failed to create iPhone 13 Pro Simulator: is Xcode installed?" && exit 1
    }
fi

echo "Booting iPhone Simulator"
xcrun simctl boot "totem-phone"
open -a "Simulator" || {
    echo "error launching iPhone Simulator: is Xcode installed?" && exit 1
}

echo "Waiting for Simulator."
xcrun simctl bootstatus "totem-phone" || {
    echo "error starting up simulator: is Xcode installed?" && exit 1
}

echo "Installing app on Simulator."
xcrun simctl install "totem-phone" "$BASE_DIR"/"totem-ios/build/Build/Products/Debug-iphonesimulator/Totem (Simulator).app" || {
    echo "error copying app to simulator: is Xcode installed? did you run ./build-totem-ios?" && exit 1
}

echo "Launching app on Simulator."
xcrun simctl launch "totem-phone" "com.test.test4444" || {
    echo "error launching app in simulator: is Xcode installed?" && exit 1
}

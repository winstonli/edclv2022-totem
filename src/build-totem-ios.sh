#!/bin/zsh
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]-$0}")
BASE_DIR="$SCRIPT_DIR"/..
setopt XTRACE

echo "Detecting architecture."
UNAME=$(uname -m)
if [[ $UNAME == 'arm64' ]]; then
    ARCH="aarch64"
elif [[ $UNAME == 'x86_64' ]]; then
    ARCH="x86_64"
else
    echo "error: unknown architecture"
    exit 1
fi
TARGET="$ARCH-apple-ios"

echo "Building totem-bridge (Rust) library for iOS Simulator ($TARGET)."
pushd "$BASE_DIR"/totem
cargo build --target $TARGET --release -p totem-bridge || {
    echo "cargo build failed: is Rust installed?" && exit 1
}
popd

echo "Copying totem-bridge (Rust) library to Frameworks."
BUILD_DIR="$BASE_DIR"/totem/target/"$TARGET"/release
FRAMEWORK_DIR="$BASE_DIR"/totem-ios/Totem/Frameworks/Simulator
mkdir -p $FRAMEWORK_DIR
cp "$BUILD_DIR"/libtotem_bridge.a "$BUILD_DIR"/totem_bridge.h "$FRAMEWORK_DIR"/

echo "Building Xcode project."
pushd "$BASE_DIR"/totem-ios
xcrun xcodebuild \
    -scheme 'Totem (Simulator)' \
    -project Totem.xcodeproj \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=iPhone 13 Pro,OS=15.2' \
    -derivedDataPath \
    build || {
        echo "xcodebuild failed: is Xcode installed?" && exit 1
    }
popd
# .app is placed in build/...

#!/bin/zsh
# Builds Clipboard.app into ./build. Pass "install" to also copy it to /Applications.
set -e
cd "$(dirname "$0")"
swift build -c release
APP=build/Clipboard.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/ClipboardApp" "$APP/Contents/MacOS/Clipboard"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built $APP"
if [[ "$1" == "install" ]]; then
    rm -rf /Applications/Clipboard.app
    cp -R "$APP" /Applications/
    echo "Installed to /Applications/Clipboard.app"
fi

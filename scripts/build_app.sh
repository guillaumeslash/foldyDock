#!/bin/bash
set -e

if [ -z "$DEVELOPER_DIR" ] && [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

CONFIGURATION="release"
ACTION="build"

while [[ $# -gt 0 ]]; do
  case $1 in
    --debug)
      CONFIGURATION="debug"
      shift
      ;;
    run)
      ACTION="run"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

echo "🚀 Compiling FolderDock ($CONFIGURATION)..."
swift build -c "$CONFIGURATION"

BIN_PATH=$(swift build -c "$CONFIGURATION" --show-bin-path)/FolderDock

APP_NAME="FolderDock.app"
DIST_DIR="build"
APP_BUNDLE="$DIST_DIR/$APP_NAME"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "📦 Packaging $APP_NAME..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

cp "$BIN_PATH" "$MACOS/FolderDock"
chmod +x "$MACOS/FolderDock"

cat <<EOF > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>fr</string>
    <key>CFBundleExecutable</key>
    <string>FolderDock</string>
    <key>CFBundleIdentifier</key>
    <string>com.folderdock.FolderDock</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>FolderDock</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

echo "✅ $APP_NAME assembled successfully in $DIST_DIR!"

if [ "$ACTION" = "run" ]; then
    echo "🌟 Launching $APP_NAME..."
    killall FolderDock 2>/dev/null || true
    sleep 0.2
    open "$APP_BUNDLE"
fi

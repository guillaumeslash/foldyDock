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

echo "🚀 Compiling FoldyDock ($CONFIGURATION)..."
swift build -c "$CONFIGURATION"

BIN_PATH=$(swift build -c "$CONFIGURATION" --show-bin-path)/FoldyDock

APP_NAME="FoldyDock.app"
DIST_DIR="build"
APP_BUNDLE="$DIST_DIR/$APP_NAME"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "📦 Packaging $APP_NAME..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

cp "$BIN_PATH" "$MACOS/FoldyDock"
chmod +x "$MACOS/FoldyDock"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f "$PROJECT_DIR/logoFoldyDock.png" ]; then
    cp "$PROJECT_DIR/logoFoldyDock.png" "$RESOURCES/logoFoldyDock.png"
elif [ -f "logoFoldyDock.png" ]; then
    cp "logoFoldyDock.png" "$RESOURCES/logoFoldyDock.png"
fi

if [ -f "$PROJECT_DIR/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/AppIcon.icns" "$RESOURCES/AppIcon.icns"
elif [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi

cat <<EOF > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>fr</string>
    <key>CFBundleExecutable</key>
    <string>FoldyDock</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.foldydock.FoldyDock</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>FoldyDock</string>
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
    killall FoldyDock 2>/dev/null || true
    sleep 0.2
    open "$APP_BUNDLE"
fi

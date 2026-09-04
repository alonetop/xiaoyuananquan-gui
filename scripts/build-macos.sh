#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/校园安全通.app"
CORE="$ROOT_DIR/macos/vendor/XiaoyuanAnQuanTong-macos-arm64"

"$ROOT_DIR/scripts/fetch-upstream.sh" "$CORE"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources/OriginalSource"

xcrun swiftc -O -target arm64-apple-macos12.0 -framework AppKit \
  "$ROOT_DIR/macos/PromptParser.swift" "$ROOT_DIR/macos/main.swift" \
  -o "$APP_DIR/Contents/MacOS/XiaoyuanAnQuanTongGUI"
cp "$ROOT_DIR/macos/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$CORE" "$APP_DIR/Contents/Resources/XiaoyuanAnQuanTong-macos-arm64"
cp "$ROOT_DIR/LICENSE" "$APP_DIR/Contents/Resources/LICENSE"
cp "$ROOT_DIR/upstream/v1.0.0/"* "$APP_DIR/Contents/Resources/OriginalSource/"
chmod 755 "$APP_DIR/Contents/MacOS/XiaoyuanAnQuanTongGUI" "$APP_DIR/Contents/Resources/XiaoyuanAnQuanTong-macos-arm64"
xattr -cr "$APP_DIR"
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

PACKAGE="$DIST_DIR/XiaoyuanAnQuanTong-GUI-macOS-arm64.zip"
rm -f "$PACKAGE"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$PACKAGE"
unzip -t "$PACKAGE" >/dev/null
echo "已生成 $PACKAGE"

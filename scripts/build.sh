#!/bin/bash
set -euo pipefail
python3 scripts/generate_templates.py
mkdir -p Build
swiftc Sources/Shared/ActionRequest.swift Sources/Shared/FileCreator.swift Tests/main.swift -o Build/core-tests
Build/core-tests
xcodegen generate
xcodebuild -project QingRightClick.xcodeproj -scheme QingRightClick -configuration Release \
  -derivedDataPath Build/Derived -destination 'generic/platform=macOS' \
  ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO build > Build/xcodebuild.log 2>&1 || {
    tail -150 Build/xcodebuild.log
    exit 1
  }
APP="Build/Derived/Build/Products/Release/QingRightClick.app"
EXT="$APP/Contents/PlugIns/FinderExtension.appex"
codesign --force --sign - --entitlements Build/Finder.entitlements "$EXT"
codesign --force --sign - "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
lipo "$APP/Contents/MacOS/QingRightClick" -verify_arch arm64 x86_64
lipo "$EXT/Contents/MacOS/FinderExtension" -verify_arch arm64 x86_64
for ext in txt md doc docx xlsx pptx; do
  cmp "Resources/Templates/blank.$ext" "$APP/Contents/Resources/Templates/blank.$ext"
done
python3 scripts/smoke_app.py "$APP"
mkdir -p Build/DMG out
ditto "$APP" Build/DMG/QingRightClick.app
ln -s /Applications Build/DMG/Applications
cp INSTALL.md Build/DMG/安装说明.txt
hdiutil create -volname "轻右键" -srcfolder Build/DMG -ov -format UDZO out/QingRightClick-0.1.0-universal.dmg
hdiutil verify out/QingRightClick-0.1.0-universal.dmg
shasum -a 256 out/*.dmg > out/SHA256SUMS.txt
echo "PASS: universal app, Finder extension, templates, signature and DMG verified"

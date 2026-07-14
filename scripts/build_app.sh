#!/bin/bash
set -euo pipefail

APP_NAME="SoundFlow"
BUILD_DIR=".build/release"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS}/MacOS"
RESOURCES_DIR="${CONTENTS}/Resources"

echo "Building ${APP_NAME}..."
swift build -c release 2>&1

echo "Generating app icon..."
mkdir -p Resources/AppIcon.appiconset
swift scripts/generate_icon.swift

echo "Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
cp Info.plist "${CONTENTS}/Info.plist"
cp SoundFlow.entitlements "${CONTENTS}/Resources/SoundFlow.entitlements"

echo "Compiling asset catalog..."
xcrun actool --compile "${RESOURCES_DIR}" --platform macosx --minimum-deployment-target 14.0 Resources/Assets.xcassets 2>/dev/null || true

echo "Done: ${APP_BUNDLE}"
echo "Run: open ${APP_BUNDLE}"

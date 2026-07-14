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

TMP_ICONSET="/tmp/soundflow_iconset_$$"
rm -rf "${TMP_ICONSET}"
cp -r Resources/AppIcon.appiconset "${TMP_ICONSET}"
iconutil --convert icns "${TMP_ICONSET}" --output "${RESOURCES_DIR}/${APP_NAME}.icns"
rm -rf "${TMP_ICONSET}"

echo "Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
cp Info.plist "${CONTENTS}/Info.plist"
cp SoundFlow.entitlements "${CONTENTS}/Resources/SoundFlow.entitlements"

echo "Done: ${APP_BUNDLE}"
echo "Run: open ${APP_BUNDLE}"

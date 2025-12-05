#!/bin/bash

# Script to build and run the Traceback SwiftUI Sample on iOS Simulator
# Usage: ./build-and-run.sh [DEVICE_NAME] [PROJECT_PATH]
#
# Examples:
#   ./build-and-run.sh "iPhone 15 Pro"
#   ./build-and-run.sh "iPhone 15 Pro" /path/to/TracebackSwiftUIExample.xcodeproj
#   ./build-and-run.sh  # Uses defaults

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DEFAULT_DEVICE="iPhone 15 Pro"
DEFAULT_PROJECT_PATH="swiftui-basic/TracebackSwiftUIExample/TracebackSwiftUIExample.xcodeproj"
SCHEME_NAME="TracebackSwiftUIExample"

# Parse arguments
DEVICE_NAME="${1:-$DEFAULT_DEVICE}"
PROJECT_PATH="${2:-$DEFAULT_PROJECT_PATH}"

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Validate project exists
if [ ! -d "$PROJECT_PATH" ]; then
    print_error "Project not found at: $PROJECT_PATH"
    exit 1
fi

print_info "Building Traceback SwiftUI Sample"
print_info "Device: $DEVICE_NAME"
print_info "Project: $PROJECT_PATH"
echo ""

# Get the device UDID
print_info "Finding simulator..."
DEVICE_UDID=$(xcrun simctl list devices available | grep "$DEVICE_NAME" | head -n 1 | grep -o -E '\([A-F0-9-]+\)' | tr -d '()')

if [ -z "$DEVICE_UDID" ]; then
    print_error "Simulator '$DEVICE_NAME' not found"
    echo ""
    print_info "Available simulators:"
    xcrun simctl list devices available | grep iPhone
    exit 1
fi

print_info "Found simulator: $DEVICE_NAME ($DEVICE_UDID)"

# Boot simulator if not already running
print_info "Booting simulator..."
xcrun simctl boot "$DEVICE_UDID" 2>/dev/null || true
open -a Simulator

# Wait for simulator to boot
print_info "Waiting for simulator to boot..."
while [ "$(xcrun simctl list devices | grep "$DEVICE_UDID" | grep -c "Booted")" -eq 0 ]; do
    sleep 1
done
print_info "Simulator booted"

# Clean build folder (optional, comment out for faster rebuilds)
print_info "Cleaning build folder..."
xcodebuild clean \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Debug \
    > /dev/null 2>&1

# Build the project
print_info "Building project..."
BUILD_DIR=$(mktemp -d)
BUILD_LOG="$BUILD_DIR/build.log"

xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$DEVICE_UDID" \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGN_ENTITLEMENTS="" \
    > "$BUILD_LOG" 2>&1

BUILD_STATUS=$?

if [ $BUILD_STATUS -ne 0 ]; then
    print_error "Build failed with status $BUILD_STATUS"
    echo ""
    print_info "Build errors:"
    grep -E "error:" "$BUILD_LOG" | head -20
    echo ""
    print_info "Full build log: $BUILD_LOG"
    exit 1
fi

print_info "Build succeeded"

# Find the .app bundle
APP_PATH=$(find "$BUILD_DIR" -name "*.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    print_error "Failed to find .app bundle"
    print_info "Build output in: $BUILD_DIR"
    exit 1
fi

print_info "Build succeeded: $APP_PATH"

# Install the app
print_info "Installing app on simulator..."
xcrun simctl install "$DEVICE_UDID" "$APP_PATH"

# Get bundle identifier
BUNDLE_ID=$(defaults read "$APP_PATH/Info.plist" CFBundleIdentifier)

# Cleanup
rm -rf "$BUILD_DIR"

echo ""
print_info "✅ Successfully installed $SCHEME_NAME on $DEVICE_NAME"
print_info "Bundle ID: $BUNDLE_ID"
echo ""
print_info "To launch the app, tap its icon in the simulator or run:"
echo "  xcrun simctl launch $DEVICE_UDID $BUNDLE_ID"
echo ""
print_warning "Note: Universal Links don't work in Simulator!"
print_warning "For full testing, deploy to a physical device."

#!/bin/bash

# Script to uninstall the Traceback SwiftUI Sample from iOS Simulator
# Usage: ./uninstall.sh [DEVICE_NAME] [BUNDLE_ID]
#
# Examples:
#   ./uninstall.sh "iPhone 15 Pro"
#   ./uninstall.sh "iPhone 15 Pro" com.custom.bundle.id
#   ./uninstall.sh  # Uses defaults

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DEFAULT_DEVICE="iPhone 15 Pro"
DEFAULT_BUNDLE_ID="com.inqbarna.traceback.samples"

# Parse arguments
DEVICE_NAME="${1:-$DEFAULT_DEVICE}"
BUNDLE_ID="${2:-$DEFAULT_BUNDLE_ID}"

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

print_info "Uninstalling Traceback SwiftUI Sample"
print_info "Device: $DEVICE_NAME"
print_info "Bundle ID: $BUNDLE_ID"
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

# Check if app is installed
print_info "Checking if app is installed..."
APP_INSTALLED=$(xcrun simctl listapps "$DEVICE_UDID" | grep -c "$BUNDLE_ID" || true)

if [ "$APP_INSTALLED" -eq 0 ]; then
    print_warning "App with bundle ID '$BUNDLE_ID' is not installed on this simulator"
    echo ""
    print_info "Installed apps:"
    xcrun simctl listapps "$DEVICE_UDID" | grep -E "Bundle|CFBundleIdentifier" | head -20
    exit 0
fi

# Uninstall the app
print_info "Uninstalling app..."
xcrun simctl uninstall "$DEVICE_UDID" "$BUNDLE_ID"

echo ""
print_info "✅ Successfully uninstalled app from $DEVICE_NAME"
print_info "Bundle ID: $BUNDLE_ID"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/boringNotch.xcodeproj"
TARGET_NAME="boringNotch"
CONFIGURATION="Release"
APP_DISPLAY_NAME="${APP_DISPLAY_NAME:-Boring Notch CN}"
APP_BUNDLE_NAME="${APP_DISPLAY_NAME}.app"
DMG_BASENAME="${DMG_BASENAME:-BoringNotchCN}"
UNNOTARIZED="${UNNOTARIZED:-0}"
if [ "$UNNOTARIZED" = "1" ]; then
  CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-Apple Development}"
else
  CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-Developer ID Application}"
fi
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"
BUILD_ROOT="${BUILD_ROOT:-/private/tmp/boringnotch-cn-release}"
ARCHIVE_PATH="$BUILD_ROOT/$DMG_BASENAME.xcarchive"
EXPORT_PATH="$BUILD_ROOT/export"
BUILD_PRODUCTS_PATH="$BUILD_ROOT/products"
CLONED_SOURCE_PACKAGES_DIR="${CLONED_SOURCE_PACKAGES_DIR:-$BUILD_ROOT/SourcePackages}"
STAGING_PATH="$BUILD_ROOT/dmg-staging"
DIST_DIR="$ROOT_DIR/dist"
EXPORT_OPTIONS="$ROOT_DIR/Configuration/ExportOptions.DeveloperID.plist"
SIGNING_XCCONFIG="$BUILD_ROOT/SigningOverrides.xcconfig"

if ! security find-identity -v -p codesigning | grep -q "$CODE_SIGN_IDENTITY"; then
  echo "error: missing code signing identity: $CODE_SIGN_IDENTITY" >&2
  if [ "$UNNOTARIZED" = "1" ]; then
    echo "Install an Apple Development certificate, or set CODE_SIGN_IDENTITY to another available local identity." >&2
  else
    echo "Install a Developer ID Application certificate before publishing outside the Mac App Store." >&2
  fi
  exit 1
fi

if [ -z "$DEVELOPMENT_TEAM" ]; then
  echo "error: DEVELOPMENT_TEAM is required, for example: DEVELOPMENT_TEAM=ABCDE12345" >&2
  exit 1
fi

if grep -q "com.apple.security.cs.disable-library-validation" "$ROOT_DIR/boringNotch/boringNotch.entitlements"; then
  echo "error: release entitlements must not disable library validation" >&2
  exit 1
fi

rm -rf "$BUILD_ROOT" "$DIST_DIR"
mkdir -p "$BUILD_ROOT" "$DIST_DIR"

{
  printf 'DEVELOPMENT_TEAM = %s\n' "$DEVELOPMENT_TEAM"
  printf 'CODE_SIGN_IDENTITY = %s\n' "$CODE_SIGN_IDENTITY"
  printf 'CODE_SIGN_IDENTITY[sdk=macosx*] = %s\n' "$CODE_SIGN_IDENTITY"
} > "$SIGNING_XCCONFIG"

if [ "$UNNOTARIZED" = "1" ]; then
  DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
  xcodebuild build \
    -project "$PROJECT_PATH" \
    -target "$TARGET_NAME" \
    -configuration "$CONFIGURATION" \
    -xcconfig "$SIGNING_XCCONFIG" \
    -clonedSourcePackagesDirPath "$CLONED_SOURCE_PACKAGES_DIR" \
    SYMROOT="$BUILD_PRODUCTS_PATH" \
    OBJROOT="$BUILD_ROOT/obj" \
    BUILD_DIR="$BUILD_PRODUCTS_PATH" \
    CONFIGURATION_BUILD_DIR="$BUILD_PRODUCTS_PATH/$CONFIGURATION" \
    ONLY_ACTIVE_ARCH=NO \
    -allowProvisioningUpdates

  APP_PATH="$(find "$BUILD_PRODUCTS_PATH/$CONFIGURATION" -maxdepth 1 -name "*.app" -type d | head -n 1)"
else
  DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
  xcodebuild archive \
    -project "$PROJECT_PATH" \
    -target "$TARGET_NAME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -xcconfig "$SIGNING_XCCONFIG" \
    -clonedSourcePackagesDirPath "$CLONED_SOURCE_PACKAGES_DIR" \
    ONLY_ACTIVE_ARCH=NO \
    -allowProvisioningUpdates

  DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -allowProvisioningUpdates

  APP_PATH="$(find "$EXPORT_PATH" -maxdepth 1 -name "*.app" -type d | head -n 1)"
fi

if [ -z "$APP_PATH" ]; then
  echo "error: built app not found" >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
if [ "$UNNOTARIZED" = "1" ]; then
  DMG_PATH="$DIST_DIR/${DMG_BASENAME}-${VERSION}-unnotarized.dmg"
else
  DMG_PATH="$DIST_DIR/${DMG_BASENAME}-${VERSION}.dmg"
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"

rm -rf "$STAGING_PATH"
mkdir -p "$STAGING_PATH"
ditto "$APP_PATH" "$STAGING_PATH/$APP_BUNDLE_NAME"
ln -s /Applications "$STAGING_PATH/Applications"

hdiutil create \
  -volname "$APP_DISPLAY_NAME" \
  -srcfolder "$STAGING_PATH" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

if [ "$UNNOTARIZED" = "1" ]; then
  echo "warning: built an unnotarized DMG. Users must remove quarantine after installing:"
  echo "  xattr -dr com.apple.quarantine \"/Applications/$APP_BUNDLE_NAME\""
elif [ "${NOTARIZE:-0}" = "1" ]; then
  if [ -n "${NOTARY_PROFILE:-}" ]; then
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  elif [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]; then
    xcrun notarytool submit "$DMG_PATH" \
      --apple-id "$APPLE_ID" \
      --team-id "$DEVELOPMENT_TEAM" \
      --password "$APPLE_APP_SPECIFIC_PASSWORD" \
      --wait
  else
    echo "error: NOTARIZE=1 requires NOTARY_PROFILE or APPLE_ID + APPLE_APP_SPECIFIC_PASSWORD" >&2
    exit 1
  fi

  xcrun stapler staple "$DMG_PATH"
  spctl -a -vvv -t open --context context:primary-signature "$DMG_PATH"
else
  echo "warning: notarization skipped. Set NOTARIZE=1 for public distribution."
fi

echo "Built release DMG: $DMG_PATH"

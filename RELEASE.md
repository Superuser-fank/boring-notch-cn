# Release Guide

This fork supports two distribution modes:

- Unnotarized DMG, similar to the current upstream Boring Notch distribution.
- Developer ID signed and notarized DMG for standard public distribution.

## Requirements

- Xcode installed at `/Applications/Xcode.app`.
- A public source repository for GPLv3 compliance.

For unnotarized distribution, an `Apple Development` certificate is enough. Users will need to bypass Gatekeeper manually.

For standard public distribution, use a paid Apple Developer Program account with a `Developer ID Application` certificate and notarization.

## Build A DMG

Find your team ID:

```bash
security find-identity -v -p codesigning
```

Build an unnotarized DMG:

```bash
DEVELOPMENT_TEAM=YOURTEAMID UNNOTARIZED=1 ./scripts/build_release.sh
```

The DMG is written to `dist/`.

Users should install the app, then run:

```bash
xattr -dr com.apple.quarantine "/Applications/Boring Notch NetEase.app"
```

This matches the practical distribution model used by upstream Boring Notch, but it is not a formal Developer ID release.

## Build A Developer ID DMG

Build a Developer ID signed DMG:

```bash
DEVELOPMENT_TEAM=YOURTEAMID ./scripts/build_release.sh
```

The DMG is written to `dist/`.

## Notarize

Recommended: store notary credentials once in Keychain:

```bash
xcrun notarytool store-credentials boringnotch-netease \
  --apple-id "you@example.com" \
  --team-id "YOURTEAMID" \
  --password "app-specific-password"
```

Then build, notarize, and staple:

```bash
DEVELOPMENT_TEAM=YOURTEAMID NOTARIZE=1 NOTARY_PROFILE=boringnotch-netease ./scripts/build_release.sh
```

## Sparkle Updates

Automatic updates are disabled until this fork has its own Sparkle appcast and EdDSA key. Do not reuse the upstream Boring Notch appcast or public key.

## GPLv3

This project is based on Boring Notch and remains GPLv3. If you distribute binaries, also provide the corresponding source code, keep the license notices, and keep third-party attributions.

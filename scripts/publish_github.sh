#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="${REPO_NAME:-boringnotch-netease}"
VISIBILITY="${VISIBILITY:-public}"
TAG="${TAG:-v2.7.3-netease.1}"
BRANCH="${BRANCH:-netease-cloud-music}"
DMG_PATH="${DMG_PATH:-dist/BoringNotchNetEase-2.7.3-unnotarized.dmg}"
REMOTE_NAME="${REMOTE_NAME:-publish}"

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh is not installed" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "error: gh is not logged in. Run: gh auth login --hostname github.com --git-protocol https --web --scopes repo" >&2
  exit 1
fi

if [ ! -f "$DMG_PATH" ]; then
  echo "error: DMG not found: $DMG_PATH" >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "error: working tree has uncommitted changes" >&2
  exit 1
fi

OWNER="$(gh api user --jq .login)"
REPO_FULL_NAME="$OWNER/$REPO_NAME"

if ! gh repo view "$REPO_FULL_NAME" >/dev/null 2>&1; then
  gh repo create "$REPO_FULL_NAME" "--$VISIBILITY" --source . --remote "$REMOTE_NAME" --description "Boring Notch fork with NetEase Cloud Music support"
elif ! git remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
  git remote add "$REMOTE_NAME" "https://github.com/$REPO_FULL_NAME.git"
fi

git push -u "$REMOTE_NAME" "$BRANCH"

if git rev-parse "$TAG" >/dev/null 2>&1; then
  git tag -f "$TAG"
else
  git tag "$TAG"
fi
git push -f "$REMOTE_NAME" "$TAG"

RELEASE_NOTES="$(mktemp)"
cat > "$RELEASE_NOTES" <<'NOTES'
## Boring Notch NetEase

This is a fork of Boring Notch with NetEase Cloud Music support.

### Install

1. Download `BoringNotchNetEase-2.7.3-unnotarized.dmg`.
2. Open the DMG and drag `Boring Notch NetEase.app` to `/Applications`.
3. Because this build is not notarized, run:

```bash
xattr -dr com.apple.quarantine "/Applications/Boring Notch NetEase.app"
```

### Notes

- This is not an official TheBoredTeam release.
- The app is Apple Development signed, not Developer ID notarized.
- Source code is provided under GPLv3.
NOTES

if gh release view "$TAG" --repo "$REPO_FULL_NAME" >/dev/null 2>&1; then
  gh release upload "$TAG" "$DMG_PATH" --repo "$REPO_FULL_NAME" --clobber
else
  gh release create "$TAG" "$DMG_PATH" --repo "$REPO_FULL_NAME" --title "Boring Notch NetEase 2.7.3" --notes-file "$RELEASE_NOTES"
fi

echo "Published: https://github.com/$REPO_FULL_NAME/releases/tag/$TAG"

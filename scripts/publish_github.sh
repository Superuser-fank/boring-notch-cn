#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="${REPO_NAME:-boring-notch-cn}"
VISIBILITY="${VISIBILITY:-public}"
TAG="${TAG:-v2.7.3-cn.9}"
BRANCH="${BRANCH:-main}"
DMG_PATH="${DMG_PATH:-dist/BoringNotchCN-2.7.3-unnotarized.dmg}"
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
  gh repo create "$REPO_FULL_NAME" "--$VISIBILITY" --source . --remote "$REMOTE_NAME" --description "Boring Notch CN fork with additional media-source support"
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
## Boring Notch CN

Boring Notch CN 是 Boring Notch 的公开源码 fork，主品牌名不使用任何第三方服务名称。本版本增加了中文设置本地化、媒体诊断、中文安装/权限帮助、网易云音乐和 QQ 音乐支持，补充中文月份/星期、农历、常见中国节日、2026 年中国法定休假和补班提示，并为文件架快速分享增加微信、QQ、钉钉、飞书快捷投递。

本版本继续补齐中文界面：首次启动引导、权限授权说明、软件更新、媒体控制布局、文件架空状态、图片处理错误提示，以及媒体来源和模式选项值已改为更适合中文用户阅读的展示文案。

微信、QQ、钉钉、飞书快捷投递会复制内容到剪贴板并打开对应应用，需要用户手动选择联系人和发送，不会自动发送消息。

### 安装

1. 下载 `BoringNotchCN-2.7.3-unnotarized.dmg`。
2. 打开 DMG，把 `Boring Notch CN.app` 拖到 `/Applications`。
3. 这个构建已签名但未 notarize，如首次打开被 Gatekeeper 拦截，可执行：

```bash
xattr -dr com.apple.quarantine "/Applications/Boring Notch CN.app"
```

### 开源与合规

- 许可证：GPLv3。完整许可证见 `LICENSE`。
- 对应源码：<https://github.com/Superuser-fank/boring-notch-cn/tree/v2.7.3-cn.9>
- 第三方声明：见 `THIRD_PARTY_NOTICES.md` 和 `THIRD_PARTY_LICENSES`。
- 这是非官方 fork，不是 TheBoredTeam 官方发布。
- 网易云音乐、QQ 音乐、Apple Music、Spotify、YouTube Music、微信、QQ、钉钉、飞书等名称仅用于说明兼容的媒体来源或可投递目标；本项目与这些第三方服务没有从属、授权、背书或赞助关系。
- 当前 DMG 为 Apple Development 签名，未进行 Developer ID notarization。
NOTES

if gh release view "$TAG" --repo "$REPO_FULL_NAME" >/dev/null 2>&1; then
  gh release edit "$TAG" --repo "$REPO_FULL_NAME" --title "Boring Notch CN 2.7.3-cn.9" --notes-file "$RELEASE_NOTES"
  gh release upload "$TAG" "$DMG_PATH" --repo "$REPO_FULL_NAME" --clobber
else
  gh release create "$TAG" "$DMG_PATH" --repo "$REPO_FULL_NAME" --title "Boring Notch CN 2.7.3-cn.9" --notes-file "$RELEASE_NOTES"
fi

echo "Published: https://github.com/$REPO_FULL_NAME/releases/tag/$TAG"

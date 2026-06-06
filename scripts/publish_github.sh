#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="${REPO_NAME:-boring-notch-cn}"
VISIBILITY="${VISIBILITY:-public}"
TAG="${TAG:-v2.7.3-cn.13}"
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

Boring Notch CN 是 Boring Notch 的公开源码 fork，主品牌名不使用任何第三方服务名称。本版本增加了中文设置本地化、媒体诊断、诊断信息复制和中文建议处理步骤、权限与安装自检、网易云音乐和 QQ 音乐支持，补充中文月份/星期、农历、常见中国节日、2026 年中国法定休假和补班提示，并为文件架快速分享增加微信、QQ、钉钉、飞书快捷投递。

本版本继续优化中国用户排查体验：媒体诊断会根据播放器是否运行、macOS 正在播放数据是否来自所选来源、是否拿到歌曲数据，给出中文建议处理步骤；“复制诊断信息”也会带上这些建议，便于反馈 GitHub issue。诊断文本包含 App/系统版本、媒体来源、播放器状态、正在播放数据状态、控制能力和关键权限状态，但不包含歌曲名、歌手名、联系人或文件内容。通用设置页的“权限与安装自检”、首次启动引导、权限授权说明、软件更新、媒体控制布局、媒体来源和模式选项、文件架菜单与图片处理弹窗也保持中文展示。

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
- 对应源码：<https://github.com/Superuser-fank/boring-notch-cn/tree/v2.7.3-cn.13>
- 第三方声明：见 `THIRD_PARTY_NOTICES.md` 和 `THIRD_PARTY_LICENSES`。
- 这是非官方 fork，不是 TheBoredTeam 官方发布。
- 网易云音乐、QQ 音乐、Apple Music、Spotify、YouTube Music、微信、QQ、钉钉、飞书等名称仅用于说明兼容的媒体来源或可投递目标；本项目与这些第三方服务没有从属、授权、背书或赞助关系。
- 当前 DMG 为 Apple Development 签名，未进行 Developer ID notarization。
NOTES

if gh release view "$TAG" --repo "$REPO_FULL_NAME" >/dev/null 2>&1; then
  gh release edit "$TAG" --repo "$REPO_FULL_NAME" --title "Boring Notch CN 2.7.3-cn.13" --notes-file "$RELEASE_NOTES"
  gh release upload "$TAG" "$DMG_PATH" --repo "$REPO_FULL_NAME" --clobber
else
  gh release create "$TAG" "$DMG_PATH" --repo "$REPO_FULL_NAME" --title "Boring Notch CN 2.7.3-cn.13" --notes-file "$RELEASE_NOTES"
fi

echo "Published: https://github.com/$REPO_FULL_NAME/releases/tag/$TAG"

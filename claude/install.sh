#!/usr/bin/env bash
set -euo pipefail

# このモジュールのディレクトリ / dotfilesルート
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${MODULE_DIR}/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${DOTFILES_DIR}/lib/common.sh"

echo "claude:"

CLAUDE_DIR="$HOME/.claude"

# ~/.claude 自体がマウントされている場合、その実体はホスト側のディレクトリなので触らない。
# ここでリンクを張るとコンテナ内の絶対パスがホストの ~/.claude に書き戻され、
# ホスト側の設定・skills のリンクが全部壊れる。
if is_mounted "$CLAUDE_DIR"; then
  echo "  [skip] $CLAUDE_DIR はマウント済み(ホストと共有)のためリンクしない"
  exit 0
fi

# 全体設定をリンク (~/.claude/settings.json)
link "${MODULE_DIR}/settings.json" "${CLAUDE_DIR}/settings.json"

# skillsは各ディレクトリを個別に ~/.claude/skills/ へリンクする。
# (skillディレクトリを claude/skills/ に追加するだけで自動リンクされる)
for skill in "${MODULE_DIR}"/skills/*/; do
  [ -d "$skill" ] || continue
  name="$(basename "$skill")"
  link "${skill%/}" "${CLAUDE_DIR}/skills/${name}"
done

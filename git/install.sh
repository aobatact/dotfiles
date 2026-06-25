#!/usr/bin/env bash
set -euo pipefail

# このモジュールのディレクトリ / dotfilesルート
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${MODULE_DIR}/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${DOTFILES_DIR}/lib/common.sh"

echo "git:"

GIT_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/git"

# XDG準拠の配置先にリンク (~/.config/git/{config,ignore})
link "${MODULE_DIR}/config" "${GIT_CONFIG_HOME}/config"
link "${MODULE_DIR}/ignore" "${GIT_CONFIG_HOME}/ignore"

# 伝統パスの ~/.gitconfig が実体だと ~/.config/git/config を上書きしてしまうため退避する
if [ -e "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
  echo "  [backup] $HOME/.gitconfig -> $HOME/.gitconfig.bak"
  rm -f "$HOME/.gitconfig.bak"
  mv "$HOME/.gitconfig" "$HOME/.gitconfig.bak"
fi

# マシン固有設定は雛形から生成する(既存があれば触らない)
LOCAL="${GIT_CONFIG_HOME}/config.local"
if [ ! -e "$LOCAL" ]; then
  mkdir -p "$GIT_CONFIG_HOME"
  cp "${MODULE_DIR}/config.local.example" "$LOCAL"
  echo "  [create] $LOCAL (雛形から生成。user.email等を編集してください)"
else
  echo "  [keep] $LOCAL (既存)"
fi

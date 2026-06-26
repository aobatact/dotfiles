#!/usr/bin/env bash
set -euo pipefail

# このモジュールのディレクトリ / dotfilesルート
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${MODULE_DIR}/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${DOTFILES_DIR}/lib/common.sh"

echo "shell:"

# 共有エイリアスを ~/.bash_aliases にリンク
# (Ubuntu標準の ~/.bashrc が ~/.bash_aliases を自動でsourceする)
link "${MODULE_DIR}/aliases" "$HOME/.bash_aliases"

# マシン固有エイリアスは雛形から生成する(既存があれば触らない)
SHELL_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/shell"
LOCAL="${SHELL_CONFIG_HOME}/aliases.local"
if [ ! -e "$LOCAL" ]; then
  mkdir -p "$SHELL_CONFIG_HOME"
  cp "${MODULE_DIR}/aliases.local.example" "$LOCAL"
  echo "  [create] $LOCAL (雛形から生成。マシン固有のaliasはここに追記してください)"
else
  echo "  [keep] $LOCAL (既存)"
fi

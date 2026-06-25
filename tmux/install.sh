#!/usr/bin/env bash
set -euo pipefail

# このモジュールのディレクトリ / dotfilesルート
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${MODULE_DIR}/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${DOTFILES_DIR}/lib/common.sh"

echo "tmux:"

SRC="${MODULE_DIR}/.tmux.conf"

# XDG準拠の配置先 (~/.config/tmux/tmux.conf)
link "$SRC" "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"

# 保険として伝統パスにも張る (~/.tmux.conf)
link "$SRC" "$HOME/.tmux.conf"

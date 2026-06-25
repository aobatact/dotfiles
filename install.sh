#!/usr/bin/env bash
set -euo pipefail

# このスクリプトが置かれているディレクトリ(dotfilesリポジトリのルート)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# リポジトリ内のtmux.confのパス(構成に合わせて調整)
SRC="${DOTFILES_DIR}/tmux/tmux.conf"

# --- XDG準拠の配置先 (~/.config/tmux/tmux.conf) ---
XDG_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
mkdir -p "$(dirname "$XDG_DEST")"
ln -sfn "$SRC" "$XDG_DEST"

# --- 保険として伝統パスにも張る (~/.tmux.conf) ---
# tmuxを別経路で起動した場合などへの備え。不要なら削除可。
ln -sfn "$SRC" "$HOME/.tmux.conf"

echo "tmux.conf linked:"
echo "  $XDG_DEST -> $SRC"
echo "  $HOME/.tmux.conf -> $SRC"

#!/usr/bin/env bash
set -euo pipefail

# このモジュールのディレクトリ / dotfilesルート
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${MODULE_DIR}/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${DOTFILES_DIR}/lib/common.sh"

echo "zed:"

# scriptsディレクトリごとリンクする (~/.config/zed/scripts)
link "${MODULE_DIR}/scripts" "${XDG_CONFIG_HOME:-$HOME/.config}/zed/scripts"

#!/usr/bin/env bash
set -euo pipefail

# このモジュールのディレクトリ / dotfilesルート
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${MODULE_DIR}/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${DOTFILES_DIR}/lib/common.sh"

echo "devc:"

# ホスト専用エイリアスをリンクする(shell/aliases が末尾でsourceする)。
# ホストでしか使わないので install-local.sh からのみ呼ばれる。
link "${MODULE_DIR}/aliases" "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliases.host"

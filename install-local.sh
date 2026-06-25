#!/usr/bin/env bash
set -euo pipefail

# ローカル(ホスト)用のフルセットアップ。
# 共通分(install.sh)に加えて、ホストでしか使わないツールもセットアップする。
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${DOTFILES_DIR}/install.sh"
bash "${DOTFILES_DIR}/zed/install.sh"

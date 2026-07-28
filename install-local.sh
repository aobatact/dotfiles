#!/usr/bin/env bash
set -euo pipefail

# ローカル(ホスト)用のフルセットアップ。
# 共通分(install-devcontainer.sh: tmux/shell/claude/git)に加えて、
# ホストでしか使わないツール(devc/zed)もセットアップする。
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${DOTFILES_DIR}/install-devcontainer.sh"
bash "${DOTFILES_DIR}/devc/install.sh"
bash "${DOTFILES_DIR}/zed/install.sh"

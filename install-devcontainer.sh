#!/usr/bin/env bash
set -euo pipefail

# 共通エントリ。devcontainerのdotfiles機能から実行される想定(devcuで明示指定)。
# devcontainer内でも使うツールだけをここでセットアップする。
# (zedのようにホストでしか使わないものは install-local.sh 側で扱う)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${DOTFILES_DIR}/tmux/install.sh"
bash "${DOTFILES_DIR}/shell/install.sh"
bash "${DOTFILES_DIR}/claude/install.sh"

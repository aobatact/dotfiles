#!/usr/bin/env bash
set -euo pipefail

# このモジュールのディレクトリ / dotfilesルート
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${MODULE_DIR}/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${DOTFILES_DIR}/lib/common.sh"

echo "git:"

GIT_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/git"

# ~/.config/git 自体がマウントされている場合、その実体はホスト側の設定なので触らない。
# コンテナ内の絶対パスでリンクを張り替えるとホストのリンクが壊れ、さらに
# トークン(credentials)や insteadOf の書き換えまでホスト側へ漏れてしまう。
if is_mounted "$GIT_CONFIG_HOME"; then
  echo "  [skip] $GIT_CONFIG_HOME はマウント済み(ホストと共有)のため何もしない"
  exit 0
fi

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
  # devcontainer 起動時にホスト側の user.email が渡されていれば埋めておく(devcu が渡す)
  if [ -n "${GIT_USER_EMAIL:-}" ]; then
    printf '\n[user]\n\temail = %s\n' "$GIT_USER_EMAIL" >>"$LOCAL"
    echo "  [create] $LOCAL (雛形から生成。user.email=${GIT_USER_EMAIL})"
  else
    echo "  [create] $LOCAL (雛形から生成。user.email等を編集してください)"
  fi
else
  echo "  [keep] $LOCAL (既存)"
fi

# --- GitHub の認証 (devcontainer 向け) ---
# devcu が --secrets-file 経由で GH_TOKEN を渡してきた場合だけ、
# HTTPS 用の credential とプロトコル書き換えを生成する。
# ホストは ssh 鍵で認証するため GH_TOKEN を持たず、この節は skip される。
TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
AUTH="${GIT_CONFIG_HOME}/config.auth"
CRED="${GIT_CONFIG_HOME}/credentials"

# トークンを credential cache に載せておく時間(秒)。既定は 12 時間。
# 切れたらホスト側から devcauth で入れ直す。
CRED_TIMEOUT="${GIT_CRED_TIMEOUT:-43200}"

if [ -n "$TOKEN" ]; then
  mkdir -p "$GIT_CONFIG_HOME"

  # config.auth は毎回生成し直す(トークンの入れ替えに追従するため)。
  # トークン自体はファイルに書かず、credential cache(メモリ常駐のデーモン)に持たせる。
  cat >"$AUTH" <<EOF
# GH_TOKEN から自動生成。手で編集しても install のたびに上書きされる。
[credential "https://github.com"]
	helper = "cache --timeout=${CRED_TIMEOUT}"
# ssh 形式のリモートURLでもトークン認証が効くように HTTPS へ書き換える。
[url "https://github.com/"]
	insteadOf = git@github.com:
	insteadOf = ssh://git@github.com/
EOF
  echo "  [create] $AUTH (GH_TOKEN から GitHub 認証を設定)"

  # 以前の版が作った平文の credentials ファイルが残っていれば消す
  if [ -e "$CRED" ]; then
    rm -f "$CRED"
    echo "  [remove] $CRED (平文保存をやめたため削除)"
  fi

  # cache デーモンへトークンを流し込む。デーモンは初回の store で起動し、
  # 以降は別セッション(devce や tmux)からも同じソケット経由で引ける。
  printf 'protocol=https\nhost=github.com\nusername=x-access-token\npassword=%s\n\n' "$TOKEN" |
    git credential approve
  echo "  [cache] GitHub のトークンを credential cache に登録 (timeout=${CRED_TIMEOUT}秒)"

  # gh は shell/aliases のラッパーが cache のトークンを GH_TOKEN として渡すので、
  # 通常はログイン不要。hosts.yml へ永続化したい場合だけ DOTFILES_GH_LOGIN=1 を指定する。
  # (gh は GH_TOKEN 環境変数を優先し、その状態では認証情報を保存できないため env から外して実行する)
  if [ -n "${DOTFILES_GH_LOGIN:-}" ] && command -v gh >/dev/null 2>&1; then
    if env -u GH_TOKEN -u GITHUB_TOKEN gh auth status >/dev/null 2>&1; then
      echo "  [keep] gh (ログイン済み)"
    elif printf '%s\n' "$TOKEN" | env -u GH_TOKEN -u GITHUB_TOKEN gh auth login --with-token >/dev/null 2>&1; then
      echo "  [login] gh (GH_TOKEN でログイン。~/.config/gh/hosts.yml に保存される)"
    else
      echo "  [warn] gh へのログインに失敗しました" >&2
    fi
  fi
else
  echo "  [skip] GH_TOKEN が無いため GitHub 認証は設定しない"
fi

#!/usr/bin/env bash
set -euo pipefail

# このモジュールのディレクトリ / dotfilesルート
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${MODULE_DIR}/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${DOTFILES_DIR}/lib/common.sh"

echo "claude:"

CLAUDE_DIR="$HOME/.claude"

# ~/.claude がマウントされている(= devcontainer)ときに、statusLine だけを
# policy tier の drop-in として入れる。
#
# ~/.claude をマウントするコンテナでは、このリポジトリの settings.json は
# 何をしても効かない。~/.claude/settings.json はホスト側で張ったシンボリックリンクで、
# コンテナ内ではリンク先(ホストの絶対パス)が存在しないため壊れている。さらに
# devcontainer.json がプロジェクトの settings.json を重ねてマウントしている場合、
# docker がそのシンボリックリンクを解決してリンク先のパスの上にマウントするので、
# 中身はプロジェクトの設定に置き換わる。
#
# そこで設定階層の最上位(userSettings < projectSettings < localSettings <
# flagSettings < policySettings)へ statusLine だけを置く。
# managed-settings.d/*.json はファイル名の昇順でディープマージされるため、
# 他の管理者設定があっても衝突しない。
install_managed_statusline() {
  local dir="/etc/claude-code/managed-settings.d"
  local file="${dir}/50-dotfiles-statusline.json"

  # ホストの /etc を絶対に触らないための保険。
  if [ ! -f /.dockerenv ]; then
    echo "  [skip] コンテナではないため managed statusLine は設定しない"
    return 0
  fi
  if ! sudo -n true 2>/dev/null; then
    echo "  [skip] sudo が使えないため managed statusLine を設定できない"
    return 0
  fi

  sudo mkdir -p "$dir"
  # ヒアドキュメント内の \" はそのまま残るので、JSON のエスケープとして機能する。
  sudo tee "$file" >/dev/null <<EOF
{
  "statusLine": {
    "command": "bash \"${MODULE_DIR}/statusline.sh\"",
    "type": "command"
  }
}
EOF
  echo "  [managed] $file"
}

# ~/.claude 自体がマウントされている場合、その実体はホスト側のディレクトリなので触らない。
# ここでリンクを張るとコンテナ内の絶対パスがホストの ~/.claude に書き戻され、
# ホスト側の設定・skills のリンクが全部壊れる。
if is_mounted "$CLAUDE_DIR"; then
  echo "  [skip] $CLAUDE_DIR はマウント済み(ホストと共有)のためリンクしない"
  install_managed_statusline
  exit 0
fi

# 全体設定をリンク (~/.claude/settings.json)
link "${MODULE_DIR}/settings.json" "${CLAUDE_DIR}/settings.json"

# settings.json の statusLine から呼ばれるスクリプト
link "${MODULE_DIR}/statusline.sh" "${CLAUDE_DIR}/statusline.sh"

# skillsは各ディレクトリを個別に ~/.claude/skills/ へリンクする。
# (skillディレクトリを claude/skills/ に追加するだけで自動リンクされる)
for skill in "${MODULE_DIR}"/skills/*/; do
  [ -d "$skill" ] || continue
  name="$(basename "$skill")"
  link "${skill%/}" "${CLAUDE_DIR}/skills/${name}"
done

#!/usr/bin/env bash
# 各installスクリプトから source して使う共通ヘルパー。

# シンボリックリンクを張る。
# 既存の実ファイル/実ディレクトリがある場合は .bak へ退避してから張り直す。
# 既にリンク(または張り替え)であれば -n で安全に上書きする。
#   link <src> <dest>
link() {
  local src="$1" dest="$2"

  if [ ! -e "$src" ]; then
    echo "  [skip] source not found: $src" >&2
    return 1
  fi

  mkdir -p "$(dirname "$dest")"

  # 既存が実体(シンボリックリンクでない)なら退避する
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    local bak="${dest}.bak"
    echo "  [backup] $dest -> $bak"
    rm -rf "$bak"
    mv "$dest" "$bak"
  fi

  ln -sfn "$src" "$dest"
  echo "  [link] $dest -> $src"
}

# 指定ディレクトリがマウントポイントかどうかを判定する。
#   is_mounted <dir>
#
# devcontainer ではホストのディレクトリがそのまま bind mount されることがある
# (例: devcontainer.json で ~/.claude をマウントする)。そこへリンクを張ると
# コンテナ内の絶対パス(/home/<コンテナユーザー>/dotfiles/...)がホスト側に
# 書き戻され、ホストのリンクが壊れる。そのため書き込み前にこれで判定する。
#
# /proc/self/mountinfo が読めない環境(非Linux等)では常に false を返す。
is_mounted() {
  local path="$1"

  [ -d "$path" ] || return 1
  [ -r /proc/self/mountinfo ] || return 1

  # mountinfo の 5 列目がマウント先のパス。
  # (ルール内の exit は END へ飛ぶため、フラグを立てて END で終了ステータスを決める)
  awk -v p="$path" '$5 == p { found = 1 } END { exit !found }' /proc/self/mountinfo
}

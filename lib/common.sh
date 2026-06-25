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

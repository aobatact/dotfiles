#!/usr/bin/env bash
# Claude Code のステータス行を組み立てる。
#
# 標準入力に来る JSON から表示に使う値だけを抜き、1行で出力する:
#   <モデル名> | Context: <n>% used | 5h: <n>%
# 値が取れなかった項目は黙って省略する。
#
# devcontainer には jq が入っていないことがあるため、grep/sed だけで解析する。
# 汎用の JSON パーサではなく、以下の性質に依存した割り切った解析:
#   - 目的のキー(`"context_window"` 等)以降を切り出せば、その中で最初に現れる
#     `used_percentage` / `display_name` が目的の値になる。
#   - 親を `{...}` ごと切り出す方式は使えない。`context_window` は入れ子の
#     `current_usage` オブジェクトを含むため。
set -uo pipefail

# 改行を潰して1行にする。整形済み JSON でも同じように扱えるようにするため。
json="$(tr -d '\n')"

# `"<key>"` が最初に現れた位置以降を返す。見つからなければ何も返さない。
after() {
  local rest="${json#*\"$1\"}"
  [ "$rest" = "$json" ] && return 1
  printf '%s' "$rest"
}

# 与えた文字列から最初の `"<key>": <値>` の生の値を返す(次の `,` か `}` まで)。
# 値そのものに `,` や `}` を含む文字列は扱えないが、対象のキーには現れない。
#
# 「キー直後の値だけを見る」のが重要。値が null のとき(セッション開始直後の
# `context_window.used_percentage` など)に、後ろにある別のキーの数値を
# 拾ってしまわないようにするため。
raw_of() {
  printf '%s' "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*[^,}]*" | head -1 |
    sed 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*$//'
}

# 文字列値を返す。ダブルクォートで囲まれていなければ(null 等)何も返さない。
str_of() {
  local v
  v="$(raw_of "$1" "$2")"
  case "$v" in
    '"'*'"') v="${v#\"}"; printf '%s' "${v%\"}" ;;
  esac
}

# 数値を返す。数字で始まらなければ(null 等)何も返さない。
num_of() {
  local v
  v="$(raw_of "$1" "$2")"
  case "$v" in
    [0-9]*) printf '%s' "$v" ;;
  esac
}

# 小数を四捨五入して整数にする。数値でなければ何も返さない。
round() {
  [ -n "$1" ] || return 0
  printf '%.0f' "$1" 2>/dev/null
}

model="$(str_of "$(after model)" display_name)"
used="$(round "$(num_of "$(after context_window)" used_percentage)")"
five="$(round "$(num_of "$(after five_hour)" used_percentage)")"

# 取れた項目だけを ` | ` で連結する(モデル名が取れなくても先頭が区切りにならないように)。
out=""
append() {
  [ -n "$1" ] || return 0
  if [ -n "$out" ]; then out="$out | $1"; else out="$1"; fi
}

append "$model"
append "${used:+Context: ${used}% used}"
append "${five:+5h: ${five}%}"

printf '%s' "$out"

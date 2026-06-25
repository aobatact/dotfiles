#!/usr/bin/env bash
set -eu

ref="$1"
# origin/ を剥がす(スクリプト内なのでZedに干渉されない)
git switch "${ref#origin/}"

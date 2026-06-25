#!/usr/bin/env bash
set -eu

SHA="$1"
SHORT="$2"

# zenity (WSLg環境ならこちらが速い)
if command -v zenity >/dev/null 2>&1 && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
  name=$(zenity --entry --title="Create Branch" --text="Branch name from ${SHORT}:") || exit 0
# PowerShell (WSLgがなくても確実に動く)
elif command -v powershell.exe >/dev/null 2>&1; then
  name=$(powershell.exe -NoProfile -Command \
    "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.Interaction]::InputBox('Branch name:', 'Create branch from ${SHORT}', '')" \
    | tr -d '\r\n')
# ターミナル入力フォールバック
else
  read -r -p "Branch name from ${SHORT}: " name
fi

[ -n "$name" ] || { echo "Cancelled."; exit 0; }
git switch -c "$name" "$SHA"

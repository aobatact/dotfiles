#!/usr/bin/env bash
set -eu

ref="$1"
branch="${ref#origin/}"

if command -v zenity >/dev/null 2>&1 && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
  zenity --question --title="Force Delete" \
    --text="Force delete branch '${branch}'?\nThis cannot be undone." \
    --default-cancel || { echo "Cancelled."; exit 0; }
elif command -v powershell.exe >/dev/null 2>&1; then
  ans=$(powershell.exe -NoProfile -Command \
    "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.Interaction]::MsgBox('Force delete branch ''${branch}''? This cannot be undone.', 'YesNo,Question,DefaultButton2', 'Force Delete')" \
    | tr -d '\r\n')
  [ "$ans" = "Yes" ] || { echo "Cancelled."; exit 0; }
else
  read -r -p "Force delete '${branch}'? [y/N] " ans
  case "$ans" in [yY]|[yY][eE][sS]) ;; *) echo "Cancelled."; exit 0 ;; esac
fi

git branch -D "$branch"
echo "Force deleted: $branch"

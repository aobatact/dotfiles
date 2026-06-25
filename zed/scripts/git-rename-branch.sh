#!/usr/bin/env bash
set -eu

REF="$1"

if command -v zenity >/dev/null 2>&1 && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
  new=$(zenity --entry --title="Rename Branch" --text="New name for ${REF}:" --entry-text="${REF}") || exit 0
elif command -v powershell.exe >/dev/null 2>&1; then
  new=$(powershell.exe -NoProfile -Command \
    "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.Interaction]::InputBox('New branch name:', 'Rename ${REF}', '${REF}')" \
    | tr -d '\r\n')
else
  read -r -p "New name for ${REF}: " new
fi

[ -n "$new" ] || { echo "Cancelled."; exit 0; }
[ "$new" = "$REF" ] && { echo "Same name, nothing to do."; exit 0; }
git branch -m "$REF" "$new"
echo "Renamed: $REF -> $new"

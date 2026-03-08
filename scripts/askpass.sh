#!/usr/bin/env bash
set -euo pipefail

GTVPN_ROOT="${GTVPN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=/dev/null
source "$GTVPN_ROOT/lib/common.sh"
load_config

prompt="${*:-Authentication required}"

if [[ -n "${SUDO_PASSWORD_KEYCHAIN_SERVICE:-}" && -n "${SUDO_PASSWORD_KEYCHAIN_ACCOUNT:-}" ]]; then
  if secret="$(keychain_get "$SUDO_PASSWORD_KEYCHAIN_SERVICE" "$SUDO_PASSWORD_KEYCHAIN_ACCOUNT" 2>/dev/null)"; then
    printf '%s\n' "$secret"
    exit 0
  fi
fi

/usr/bin/osascript - "$prompt" <<'APPLESCRIPT'
on run argv
  set promptText to item 1 of argv
  set dialogResult to display dialog promptText default answer "" with hidden answer buttons {"Cancel", "OK"} default button "OK"
  return text returned of dialogResult
end run
APPLESCRIPT

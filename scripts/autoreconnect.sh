#!/usr/bin/env bash
set -euo pipefail

GTVPN_ROOT="${GTVPN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=/dev/null
source "$GTVPN_ROOT/lib/common.sh"
load_config
ensure_runtime_dirs

if ! autoreconnect_enabled; then
  exit 0
fi

if is_connected || is_connecting; then
  exit 0
fi

printf '[%s] openconnect is not running; reconnecting\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" >> "$AUTORECONNECT_LOG"
nohup env \
  "GTVPN_ROOT=$GTVPN_ROOT" \
  "GTVPN_CONFIG=$GTVPN_CONFIG" \
  "GTVPN_USER_HOME=$(_gtvpn_runtime_home)" \
  "GTVPN_CLI_PATH=${GTVPN_CLI_PATH:-$GTVPN_ROOT/bin/gtvpn}" \
  "$GTVPN_ROOT/bin/gtvpn" connect >> "$AUTORECONNECT_LOG" 2>&1 &
disown || true

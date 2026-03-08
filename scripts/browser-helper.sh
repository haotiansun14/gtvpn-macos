#!/usr/bin/env bash
set -euo pipefail

GTVPN_ROOT="${GTVPN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=/dev/null
source "$GTVPN_ROOT/lib/common.sh"
load_config

target="${1:-}"
[[ -n "$target" ]] || exit 1

open_command=(/usr/bin/open)
if [[ -n "$EXTERNAL_BROWSER_APP" ]]; then
  open_command+=( -a "$EXTERNAL_BROWSER_APP" )
fi

run_as_user() {
  if [[ "$(id -u)" -eq 0 && -n "${GTVPN_RUNTIME_USER:-}" ]]; then
    exec /usr/bin/sudo -u "$GTVPN_RUNTIME_USER" "$@"
  fi
  exec "$@"
}

if [[ -n "$EXTERNAL_BROWSER_CMD" ]]; then
  export GTVPN_BROWSER_TARGET="$target"
  if [[ "$(id -u)" -eq 0 && -n "${GTVPN_RUNTIME_USER:-}" ]]; then
    exec /usr/bin/sudo -u "$GTVPN_RUNTIME_USER" env "GTVPN_BROWSER_TARGET=$target" /bin/sh -lc "$EXTERNAL_BROWSER_CMD"
  fi
  exec /bin/sh -lc "$EXTERNAL_BROWSER_CMD"
fi

run_as_user "${open_command[@]}" "$target"

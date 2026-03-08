#!/usr/bin/env bash
set -euo pipefail

GTVPN_ROOT="${GTVPN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=/dev/null
source "$GTVPN_ROOT/lib/common.sh"
load_config
ensure_runtime_dirs
require_commands openconnect osascript

export SUDO_ASKPASS="$ASKPASS_SCRIPT_PATH"
GTVPN_RUNTIME_USER="$(id -un)"
export GTVPN_RUNTIME_USER

cmd=(
  sudo -A env
  "GTVPN_ROOT=$GTVPN_ROOT"
  "GTVPN_CONFIG=$GTVPN_CONFIG"
  "GTVPN_USER_HOME=$(_gtvpn_runtime_home)"
  "GTVPN_RUNTIME_USER=$GTVPN_RUNTIME_USER"
  "GTVPN_LOG_DIR=$LOG_DIR"
  "$(openconnect_bin)"
  "--protocol=$VPN_PROTOCOL"
  "--os=$VPN_OS"
  "--external-browser=$BROWSER_HELPER_PATH"
  "--pid-file=$OPENCONNECT_PID_FILE"
  "--script=$VPNC_SCRIPT_PATH"
)

if [[ -n "$VPN_USER" ]]; then
  cmd+=("--user=$VPN_USER")
fi

if [[ -n "$VPN_GATEWAY_LABEL" ]]; then
  cmd+=("--authgroup=$VPN_GATEWAY_LABEL")
fi

if [[ -n "$VPN_SERVERCERT" ]]; then
  cmd+=("--servercert=$VPN_SERVERCERT")
fi

for resolve in $OPENCONNECT_RESOLVES; do
  cmd+=("--resolve=$resolve")
done

for arg in $OPENCONNECT_EXTRA_ARGS; do
  cmd+=("$arg")
done

cmd+=("$VPN_PORTAL")

control_log_line "browser helper starting"
exec "${cmd[@]}"

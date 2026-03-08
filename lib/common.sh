# shellcheck shell=bash

set -euo pipefail

if [[ -z "${GTVPN_ROOT:-}" ]]; then
  GTVPN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

_gtvpn_runtime_home() {
  printf '%s\n' "${GTVPN_USER_HOME:-$HOME}"
}

load_config() {
  local runtime_home
  runtime_home="$(_gtvpn_runtime_home)"

  GTVPN_CONFIG="${GTVPN_CONFIG:-$runtime_home/.config/gtvpn/config.env}"
  GTVPN_CONFIG_DIR="$(dirname "$GTVPN_CONFIG")"

  if [[ -f "$GTVPN_CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$GTVPN_CONFIG"
  fi

  VPN_NAME="${VPN_NAME:-Georgia Tech VPN}"
  VPN_PROTOCOL="${VPN_PROTOCOL:-gp}"
  VPN_PORTAL="${VPN_PORTAL:-vpn.gatech.edu}"
  VPN_GATEWAY_LABEL="${VPN_GATEWAY_LABEL:-DC Gateway}"
  VPN_USER="${VPN_USER:-}"
  VPN_OS="${VPN_OS:-mac-intel}"
  VPN_SERVERCERT="${VPN_SERVERCERT:-}"
  OPENCONNECT_RESOLVES="${OPENCONNECT_RESOLVES:-vpn.gatech.edu:143.215.254.43 dc-ext-gw.vpn.gatech.edu:128.61.110.1}"
  OPENCONNECT_EXTRA_ARGS="${OPENCONNECT_EXTRA_ARGS:-}"
  AUTH_MODE="${AUTH_MODE:-password}"
  PASSWORD_KEYCHAIN_SERVICE="${PASSWORD_KEYCHAIN_SERVICE:-gtvpn-openconnect}"
  PASSWORD_KEYCHAIN_ACCOUNT="${PASSWORD_KEYCHAIN_ACCOUNT:-${VPN_USER:-}}"
  MFA_MODE="${MFA_MODE:-static}"
  MFA_RESPONSES="${MFA_RESPONSES:-push1 push2 phone1 phone2}"
  MFA_KEYCHAIN_SERVICE="${MFA_KEYCHAIN_SERVICE:-gtvpn-mfa}"
  MFA_KEYCHAIN_ACCOUNT="${MFA_KEYCHAIN_ACCOUNT:-${VPN_USER:-}}"
  MFA_COMMAND="${MFA_COMMAND:-}"
  EXTERNAL_BROWSER_APP="${EXTERNAL_BROWSER_APP:-}"
  EXTERNAL_BROWSER_CMD="${EXTERNAL_BROWSER_CMD:-}"
  SUDO_PASSWORD_KEYCHAIN_SERVICE="${SUDO_PASSWORD_KEYCHAIN_SERVICE:-gtvpn-sudo}"
  SUDO_PASSWORD_KEYCHAIN_ACCOUNT="${SUDO_PASSWORD_KEYCHAIN_ACCOUNT:-$USER}"
  VPN_TUNNEL_INTERFACE_PREFIX="${VPN_TUNNEL_INTERFACE_PREFIX:-utun}"
  VPN_TUNNEL_IP_PREFIX="${VPN_TUNNEL_IP_PREFIX:-10.}"
  GT_NET_ROUTES="${GT_NET_ROUTES:-128.61.0.0/16 130.207.0.0/16 143.215.0.0/16}"
  GT_DNS_HOSTS="${GT_DNS_HOSTS:-130.207.244.244 130.207.244.251}"
  GT_SCOPED_RESOLVER_DOMAINS="${GT_SCOPED_RESOLVER_DOMAINS:-gatech.edu cc.gatech.edu pace.gatech.edu vpn.gatech.edu}"
  LOCAL_DNS_FALLBACK="${LOCAL_DNS_FALLBACK:-75.75.75.75}"
  STATE_DIR="${STATE_DIR:-$runtime_home/Library/Application Support/gtvpn}"
  LOG_DIR="${LOG_DIR:-$runtime_home/Library/Logs/gtvpn}"
  OPENCONNECT_PID_FILE="${OPENCONNECT_PID_FILE:-$STATE_DIR/openconnect.pid}"
  CONTROL_LOG="${CONTROL_LOG:-$LOG_DIR/control.log}"
  OPENCONNECT_LOG="${OPENCONNECT_LOG:-$LOG_DIR/openconnect.log}"
  ROUTE_LOG="${ROUTE_LOG:-$LOG_DIR/route.log}"
  AUTORECONNECT_LOG="${AUTORECONNECT_LOG:-$LOG_DIR/autoreconnect.log}"
  AUTORECONNECT_SENTINEL="${AUTORECONNECT_SENTINEL:-$GTVPN_CONFIG_DIR/autoreconnect.enabled}"
  AUTORECONNECT_INTERVAL="${AUTORECONNECT_INTERVAL:-600}"
  SWIFTBAR_PLUGIN_DIR="${SWIFTBAR_PLUGIN_DIR:-$runtime_home/Documents/SwiftBarPlugins}"
  SWIFTBAR_PLUGIN_PATH="${SWIFTBAR_PLUGIN_PATH:-$SWIFTBAR_PLUGIN_DIR/gtvpn.1m.sh}"
  LAUNCH_AGENT_LABEL="${LAUNCH_AGENT_LABEL:-edu.gatech.gtvpn.autoreconnect}"
  LAUNCH_AGENT_PATH="${LAUNCH_AGENT_PATH:-$runtime_home/Library/LaunchAgents/${LAUNCH_AGENT_LABEL}.plist}"
  VPNC_SCRIPT_PATH="${VPNC_SCRIPT_PATH:-$GTVPN_ROOT/scripts/vpnc-wrapper.sh}"
  ASKPASS_SCRIPT_PATH="${ASKPASS_SCRIPT_PATH:-$GTVPN_ROOT/scripts/askpass.sh}"
  BROWSER_HELPER_PATH="${BROWSER_HELPER_PATH:-$GTVPN_ROOT/scripts/browser-helper.sh}"
  CONNECT_EXPECT_PATH="${CONNECT_EXPECT_PATH:-$GTVPN_ROOT/scripts/connect.expect}"
  CONNECT_BROWSER_PATH="${CONNECT_BROWSER_PATH:-$GTVPN_ROOT/scripts/connect-browser.sh}"
  AUTORECONNECT_SCRIPT_PATH="${AUTORECONNECT_SCRIPT_PATH:-$GTVPN_ROOT/scripts/autoreconnect.sh}"
  DEFAULT_VPNC_SCRIPT="${DEFAULT_VPNC_SCRIPT:-/opt/homebrew/etc/vpnc/vpnc-script}"
}

ensure_runtime_dirs() {
  mkdir -p "$GTVPN_CONFIG_DIR" "$STATE_DIR" "$LOG_DIR"
}

control_log_line() {
  ensure_runtime_dirs
  printf '[%s] %s\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$CONTROL_LOG"
}

fatal() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_commands() {
  local missing=0
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf 'Missing dependency: %s\n' "$cmd" >&2
      missing=1
    fi
  done
  (( missing == 0 )) || exit 1
}

require_config_value() {
  local name="$1"
  local value="${!name:-}"
  [[ -n "$value" ]] || fatal "Set $name in $GTVPN_CONFIG"
}

openconnect_bin() {
  command -v openconnect
}

expect_bin() {
  command -v expect
}

keychain_get() {
  local service="$1"
  local account="$2"
  /usr/bin/security find-generic-password -a "$account" -s "$service" -w
}

keychain_set() {
  local service="$1"
  local account="$2"
  local secret="$3"
  /usr/bin/security add-generic-password -U -a "$account" -s "$service" -w "$secret" >/dev/null
}

keychain_delete() {
  local service="$1"
  local account="$2"
  /usr/bin/security delete-generic-password -a "$account" -s "$service" >/dev/null 2>&1 || true
}

prompt_secret() {
  local prompt="$1"
  local secret
  if [[ -t 0 && -t 1 ]]; then
    read -r -s -p "$prompt: " secret
    printf '\n' >&2
    printf '%s' "$secret"
    return 0
  fi
  "$ASKPASS_SCRIPT_PATH" "$prompt"
}

is_connected() {
  tracked_openconnect_pids >/dev/null
}

tracked_openconnect_pids() {
  local pid

  if [[ -f "$OPENCONNECT_PID_FILE" ]]; then
    pid="$(<"$OPENCONNECT_PID_FILE")"
    if [[ "$pid" =~ ^[0-9]+$ ]] && /bin/ps -p "$pid" -o comm= 2>/dev/null | /usr/bin/grep -qx "openconnect"; then
      printf '%s\n' "$pid"
      return 0
    fi
    rm -f "$OPENCONNECT_PID_FILE"
  fi

  /usr/bin/pgrep -f "openconnect.*${VPNC_SCRIPT_PATH}" 2>/dev/null | /usr/bin/sort -u
}

is_connecting() {
  pgrep -f "$CONNECT_EXPECT_PATH" >/dev/null 2>&1 || pgrep -f "$CONNECT_BROWSER_PATH" >/dev/null 2>&1
}

vpn_tunnel_details() {
  local ifname ip
  while IFS= read -r ifname; do
    [[ -n "$ifname" ]] || continue
    ip="$(/sbin/ifconfig "$ifname" 2>/dev/null | /usr/bin/awk -v prefix="$VPN_TUNNEL_IP_PREFIX" '$1 == "inet" && index($2, prefix) == 1 { print $2; exit }')"
    if [[ -n "$ip" ]]; then
      printf '%s %s\n' "$ifname" "$ip"
      return 0
    fi
  done < <(/sbin/ifconfig 2>/dev/null | /usr/bin/awk -v prefix="$VPN_TUNNEL_INTERFACE_PREFIX" '$1 ~ ("^" prefix) { gsub(":", "", $1); print $1 }')
  return 1
}

status_code() {
  if is_connected; then
    if vpn_tunnel_details >/dev/null 2>&1; then
      printf 'connected\n'
    else
      printf 'connecting\n'
    fi
  elif is_connecting; then
    printf 'connecting\n'
  else
    printf 'disconnected\n'
  fi
}

status_text() {
  local status
  status="$(status_code)"
  case "$status" in
    connected)
      local details
      details="$(vpn_tunnel_details || true)"
      printf 'GT VPN connected (%s)\n' "$details"
      ;;
    connecting)
      printf 'GT VPN connecting\n'
      ;;
    *)
      printf 'GT VPN disconnected\n'
      ;;
  esac
}

autoreconnect_enabled() {
  [[ -f "$AUTORECONNECT_SENTINEL" ]]
}

cidr_net() {
  printf '%s\n' "${1%%/*}"
}

cidr_prefix() {
  printf '%s\n' "${1##*/}"
}

cidr_to_mask() {
  local prefix="$1"
  local full=$(( prefix / 8 ))
  local remainder=$(( prefix % 8 ))
  local octets=()
  local i octet

  for ((i = 0; i < 4; i++)); do
    if (( i < full )); then
      octet=255
    elif (( i == full && remainder > 0 )); then
      octet=$(( 256 - 2 ** (8 - remainder) ))
    else
      octet=0
    fi
    octets+=("$octet")
  done

  local IFS='.'
  printf '%s\n' "${octets[*]}"
}

render_template() {
  local template="$1"
  local destination="$2"
  local cli_path="$3"
  local interval="$4"
  local launch_agent_label="$5"
  local log_dir="$6"

  /usr/bin/sed \
    -e "s|__CLI_PATH__|$cli_path|g" \
    -e "s|__AUTORECONNECT_INTERVAL__|$interval|g" \
    -e "s|__LAUNCH_AGENT_LABEL__|$launch_agent_label|g" \
    -e "s|__LOG_DIR__|$log_dir|g" \
    "$template" > "$destination"
}

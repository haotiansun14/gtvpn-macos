#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_TARGET="${GTVPN_CONFIG:-$HOME/.config/gtvpn/config.env}"
CONFIG_DIR="$(dirname "$CONFIG_TARGET")"
BIN_DIR="${GTVPN_BIN_DIR:-$HOME/.local/bin}"
CLI_LINK="$BIN_DIR/gtvpn"

mkdir -p "$CONFIG_DIR" "$BIN_DIR"

if [[ ! -f "$CONFIG_TARGET" ]]; then
  cp "$ROOT_DIR/config/config.env.example" "$CONFIG_TARGET"
  echo "Created config template at $CONFIG_TARGET"
else
  echo "Keeping existing config at $CONFIG_TARGET"
fi

ln -sfn "$ROOT_DIR/bin/gtvpn" "$CLI_LINK"
echo "Installed CLI symlink at $CLI_LINK"

export GTVPN_CONFIG="$CONFIG_TARGET"
export GTVPN_CLI_PATH="$CLI_LINK"

"$ROOT_DIR/bin/gtvpn" install-switchbar
if ! "$ROOT_DIR/bin/gtvpn" install-autoreconnect; then
  echo "Warning: LaunchAgent install failed. You can retry later with: $CLI_LINK install-autoreconnect"
fi

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo
  echo "Add $BIN_DIR to PATH to run 'gtvpn' directly."
fi

echo
echo "Next steps:"
echo "  1. Edit $CONFIG_TARGET"
echo "  2. Store your password: $CLI_LINK password set"
echo "  3. Connect: $CLI_LINK connect"

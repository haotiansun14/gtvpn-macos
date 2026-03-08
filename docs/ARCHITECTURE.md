# Architecture

## Connection flow

1. `gtvpn connect` reads `~/.config/gtvpn/config.env`.
2. For `AUTH_MODE=password`, `scripts/connect-password.sh` exports the config and launches `scripts/connect.expect`.
3. `scripts/connect.expect` pulls the password from Keychain, answers GlobalProtect prompts, and runs `sudo -A openconnect`.
4. `scripts/vpnc-wrapper.sh` wraps Homebrew's `vpnc-script` and then corrects routing and DNS so:
   - Georgia Tech traffic stays on the tunnel.
   - the default internet route stays local.
   - stale GT DNS settings are removed after connect and disconnect.
5. `gtvpn disconnect` kills the OpenConnect process and the wrapper cleans up the extra routes.

## Browser/passkey mode

If `AUTH_MODE=browser`, the CLI launches OpenConnect with `--external-browser` and `scripts/browser-helper.sh`.
That helper opens the auth target in the logged-in user's browser, which is the cleanest way to support browser-driven SSO or passkey flows without hardcoding credentials.

## Integration points

- SwiftBar calls `gtvpn menu` through a rendered plugin.
- launchd calls `gtvpn run-autoreconnect` on an interval.
- All user-specific state lives under `~/.config/gtvpn`, `~/Library/Application Support/gtvpn`, and `~/Library/Logs/gtvpn`.

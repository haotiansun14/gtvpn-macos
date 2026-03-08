# gtvpn-macos

A standalone macOS project for Georgia Tech GlobalProtect VPN that keeps the local internet route intact while sending Georgia Tech traffic through the tunnel.

## Features

- password autofill from the macOS Keychain
- browser/passkey auth mode for external-browser flows
- SwiftBar integration
- CLI connect, disconnect, toggle, status, and health checks
- launchd auto-reconnect support
- split-tunnel-safe route and DNS cleanup so GT SSH works without hijacking all internet traffic
- no hardcoded personal credentials in the repository

## Requirements

- macOS
- Homebrew `openconnect`
- `expect`
- SwiftBar (optional)

Install the tools if needed:

```bash
brew install openconnect expect
```

## Quick start

```bash
git clone <your-fork-or-repo-url> gtvpn-macos
cd gtvpn-macos
./install.sh
```

Then:

1. Edit `~/.config/gtvpn/config.env`.
2. Store your GT password in Keychain:
   ```bash
   gtvpn password set
   ```
3. Optional: store your macOS admin password for one-click SwiftBar or CLI elevation:
   ```bash
   gtvpn sudo-password set
   ```
4. Connect:
   ```bash
   gtvpn connect
   ```

## Auth modes

### Password mode

This is the known-good path for the GT deployment this project was debugged against.

```bash
AUTH_MODE="password"
MFA_MODE="static"
MFA_RESPONSES="push1 push2 phone1 phone2"
```

Supported MFA sources in password mode:

- `static`: fixed responses, rotated on Duo `512`
- `prompt`: prompt on each challenge
- `keychain`: read one or more responses from Keychain
- `command`: run a command and use stdout
- `none`: send an empty challenge response

### Browser/passkey mode

Use this when your portal supports OpenConnect external-browser auth and you want the sign-in to happen in a real browser with SSO/passkeys.

```bash
AUTH_MODE="browser"
EXTERNAL_BROWSER_APP="Google Chrome"
```

Or use a custom command:

```bash
AUTH_MODE="browser"
EXTERNAL_BROWSER_CMD='open -a "Google Chrome" "$GTVPN_BROWSER_TARGET"'
```

Note: browser/passkey support depends on what the VPN portal actually advertises. If the server does not support an external-browser flow, use password mode.

## CLI

```bash
gtvpn connect
gtvpn disconnect
gtvpn toggle
gtvpn status
gtvpn doctor
gtvpn sudo-password set
gtvpn enable-autoreconnect
gtvpn disable-autoreconnect
gtvpn install-switchbar
gtvpn install-autoreconnect
```

## SwiftBar

`./install.sh` renders a `gtvpn.1m.sh` plugin into `~/Documents/SwiftBarPlugins` by default.
The plugin shows connection state and exposes connect/disconnect, auto-reconnect, public IP, and doctor actions.

## Project layout

- `bin/gtvpn`: main CLI
- `config/config.env.example`: user config template
- `scripts/connect.expect`: password auth automation
- `scripts/connect-browser.sh`: browser/passkey auth entrypoint
- `scripts/vpnc-wrapper.sh`: split-tunnel route and DNS corrections
- `templates/`: rendered SwiftBar and launchd assets
- `docs/`: architecture and troubleshooting notes
- `docs/RELEASE_CHECKLIST.md`: pre-release manual validation gates

## Validation

Run the shell syntax checks:

```bash
make check
make lint
```

For a real end-to-end validation after setup:

```bash
gtvpn connect
curl -4 --max-time 8 https://ipinfo.io/json
dig +short warriors.cc.gatech.edu
ssh -v login-phoenix 'exit'
gtvpn disconnect
```

# Security

This project is designed so the repository can be published without leaking personal credentials.

- `VPN_USER` lives in `~/.config/gtvpn/config.env` and is never committed by default.
- The VPN password is stored in the macOS Keychain via `gtvpn password set`.
- The macOS admin password can optionally be stored in the macOS Keychain via `gtvpn sudo-password set` for one-click GUI flows.
- Optional MFA secrets can also live in the macOS Keychain via `gtvpn mfa set`.
- The route/DNS wrapper only stores logs and pid files under `~/Library`, not secrets.
- Do not commit your local `config.env`, screenshots, or log files if they contain sensitive hostnames or IPs.
- When you run `gtvpn password set`, `gtvpn sudo-password set`, or `gtvpn mfa set`, the secret is briefly visible in the process table (`ps aux`) because the macOS `security` CLI passes it as a command-line argument. This is a platform limitation of `/usr/bin/security add-generic-password`; there is no stdin-based alternative. The exposure window is sub-second and only affects the local machine. On a single-user workstation this is low risk.

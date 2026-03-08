# Release Checklist

A release is not ready until all of the following are true on a real macOS workstation:

## Static checks

```bash
make check
make lint
```

## Password auth path

1. `gtvpn connect`
2. Approve the macOS password prompt, or store it ahead of time with `gtvpn sudo-password set`.
3. Approve the VPN MFA challenge.
4. Confirm `gtvpn status` shows `connected`.
5. Confirm public internet still uses the local route:
   ```bash
   curl -4 --max-time 8 https://ipinfo.io/json
   ```
6. Confirm a GT route is reachable:
   ```bash
   nc -vz 128.61.254.95 22
   ```
7. Disconnect:
   ```bash
   gtvpn disconnect
   ```
8. Confirm `gtvpn status` shows `disconnected`.

## Browser/passkey path

If browser mode is enabled for the release target:

1. Set `AUTH_MODE="browser"`.
2. Run `gtvpn connect`.
3. Complete the browser flow.
4. Repeat the same connectivity and disconnect checks.

## GUI integrations

- SwiftBar plugin renders and connect/disconnect actions work.
- launchd auto-reconnect is installed and does nothing when the sentinel is disabled.

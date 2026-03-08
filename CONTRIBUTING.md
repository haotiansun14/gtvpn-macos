# Contributing

## Development expectations

- Keep the repository free of personal credentials and machine-specific values.
- Put secrets in Keychain or in the user's private config under `~/.config/gtvpn`.
- Preserve split-tunnel behavior: GT traffic through the tunnel, default internet route left local.
- Prefer small, reviewable changes and update docs when behavior changes.

## Local validation

```bash
make check
```

For behavior changes, also verify:

```bash
gtvpn connect
curl -4 --max-time 8 https://ipinfo.io/json
dig +short vpn.gatech.edu
gtvpn disconnect
```

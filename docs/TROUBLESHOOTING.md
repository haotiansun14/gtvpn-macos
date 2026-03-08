# Troubleshooting

## Internet gets slow after connect

This usually means the VPN server left DNS or a default route behind.
Check:

```bash
gtvpn doctor
scutil --dns | sed -n '1,220p'
netstat -rn -f inet | head -n 60
```

The wrapper is expected to:

- remove tunnel default routes on the VPN `utun` interface,
- restore DHCP DNS on the primary local interface,
- remove stale `/etc/resolver/gatech.edu` style files,
- rewrite `/var/run/resolv.conf` to a non-GT nameserver.

## SwiftBar click does nothing

The most common cause is a missing `sudo` prompt path. This project uses `SUDO_ASKPASS` with an AppleScript dialog so GUI launches can still elevate.

Verify:

```bash
gtvpn install-switchbar
gtvpn doctor
```

If you chose to store the sudo password in Keychain and auth now fails immediately, clear and re-set it:

```bash
gtvpn sudo-password clear
gtvpn sudo-password set
```

## GT hosts connect but public internet fails

The split-tunnel-safe routes should be limited to:

- `128.61.0.0/16`
- `130.207.0.0/16`
- `143.215.0.0/16`

If you see a VPN-scoped default route, inspect `~/Library/Logs/gtvpn/route.log`.

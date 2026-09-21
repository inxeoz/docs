---
title: "Getting MotionPro VPN Working on Arch Linux (Every Fix I Found)"
date: 2026-07-26
draft: false
tags: ["motionpro", "vpn", "archlinux", "networking", "wayland", "qt"]
categories: ["Tech"]
viewMode: docs
showToc: true
---

MotionPro is the VPN client for Array Networks' AG SSL VPN appliances. Official builds only target Windows, macOS, Ubuntu, RedHat, and CentOS — there's no native Arch package from the vendor. This guide walks through getting it fully working on Arch, based on a real troubleshooting session that hit every common failure point.

## Overview

1. Install MotionPro (via AUR preferred, or the Ubuntu `.sh` installer as fallback)
2. Fix the daemon (`vpnd`) so it actually starts and runs with the right privileges
3. Fix the GUI's display backend (Qt platform plugin) if it won't launch
4. Configure the connection profile correctly
5. Resolve tunnel/network conflicts with other VPN or DNS-tunneling software

## 1. Install MotionPro

### Preferred: AUR

```bash
yay -S motionpro motionpro-gui
```

This installs proper Arch-native binaries and file locations under `/opt/MotionPro/` and `/usr/bin/MotionPro`.

### Fallback: Vendor's Ubuntu Installer

```bash
chmod +x MotionPro_Linux_Ubuntu_x64.sh
sudo ./MotionPro_Linux_Ubuntu_x64.sh
```

You'll likely see output like:

```
cp: cannot create regular file '/etc/init.d/': Not a directory
installing vpnd...
installing MotionPro...
./install.sh: line 132: update-rc.d: command not found
./install.sh: line 133: service: command not found
install MotionPro successfully.
```

This is normal on Arch. The binaries still get installed correctly — only the Debian-specific service registration fails. We fix daemon startup manually in the next step.

> Don't run this installer inside a toolbox/distrobox container. VPN clients need to create real `tun` network interfaces and modify host routing tables.

## 2. Get the vpnd Daemon Running

MotionPro's GUI doesn't talk to the network directly — it hands off tunnel setup to a background daemon called `vpnd`, which needs root privileges.

### Check if vpnd Is Running

```bash
ps aux | grep vpnd
```

If it's not listed, or running under a non-root UID, it won't have permission to build the tunnel.

### Start It as Root

```bash
sudo pkill vpnd
sudo /usr/bin/vpnd &
```

Confirm it's running as root:

```bash
ps aux | grep vpnd
```

### Check the tun Kernel Module

```bash
lsmod | grep tun
ls -l /dev/net/tun
sudo modprobe tun
```

### Make It Persistent Across Reboots

```ini
# /etc/systemd/system/vpnd.service
[Unit]
Description=MotionPro VPN daemon
After=network.target

[Service]
ExecStart=/usr/bin/vpnd
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now vpnd
```

## 3. Fix the GUI if It Won't Launch

Launching MotionPro may fail with a Qt platform plugin error on Wayland:

```
This application failed to start because it could not find or load the Qt platform plugin "wayland;xcb".
```

Force it to use the `xcb` plugin:

```bash
QT_QPA_PLATFORM=xcb MotionPro
```

If that works, wrap it in a launcher script or export the variable in your shell profile.

You may also see harmless messages:

```
/usr/bin/MotionPro: line 9: runlevel: command not found
cp: cannot stat '/opt/MotionPro/motionpro.ini': No such file or directory
```

These are Debian leftovers in the wrapper script — they don't affect functionality.

## 4. Configure the Connection Profile

When MotionPro opens, fill in:

| Field | What to Enter |
|-------|---------------|
| **Site Name** | Any label — e.g. `MyOrg VPN` |
| **Host** | `<gateway-ip>:<port>` — e.g. `198.51.100.10:443`. Leave off any alias unless your admin requires one. |
| **Username** | Your VPN account username |
| **Password** | Entered at connect time |
| **Mode** | `AutoDetect`, unless told otherwise |

### Troubleshooting

- **"fails to obtain the AAA method"**: Client couldn't fetch gateway's auth config. Check DNS resolution and basic connectivity. Remove any alias from the host field.
- **Login failure after entering credentials**: Server-side authentication rejection. Verify your password and account status with your VPN admin.

## 5. Resolve Tunnel Conflicts

If login succeeds but you get:

```
The MotionPro client fails to configure the L3VPN tunnel. Please check your installation.
```

...and `vpnd` is confirmed running as root, the most common cause is another VPN or tunneling client already active.

Check for and disconnect them:

```bash
warp-cli disconnect
warp-cli status
ip a
```

Then retry connecting in MotionPro.

> You generally can't run two full-tunnel VPN clients simultaneously without specific split-tunnel configuration on one or both.

## Summary Checklist

- [ ] Installed via AUR (preferred) or the Ubuntu `.sh` installer
- [ ] `vpnd` confirmed running **as root**
- [ ] `tun` kernel module loaded, `/dev/net/tun` present
- [ ] GUI launches (use `QT_QPA_PLATFORM=xcb` if needed)
- [ ] Connection profile uses plain `host:port`, no unnecessary alias
- [ ] No conflicting VPN/tunnel software running at connect time
- [ ] (Optional) systemd unit created for `vpnd` so it survives reboots

## Launch Script

```bash
#!/usr/bin/env bash
#
# start-motion-pro-gui.sh
#
# Sets up prerequisites and launches the MotionPro GUI client on Arch Linux.

set -uo pipefail

MOTIONPRO_BIN="${MOTIONPRO_BIN:-/opt/MotionPro/MotionPro}"
VPND_BIN="${VPND_BIN:-$(command -v vpnd || echo /usr/bin/vpnd)}"

log()  { printf '\033[1;34m[*]\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }
err()  { printf '\033[1;31m[x]\033[0m %s\n' "$1"; }

# 1. Sanity checks
if [[ ! -x "$MOTIONPRO_BIN" ]]; then
    err "MotionPro binary not found (looked for: $MOTIONPRO_BIN)."
    exit 1
fi

if [[ ! -x "$VPND_BIN" ]]; then
    err "vpnd binary not found (looked for: $VPND_BIN)."
    exit 1
fi

# 2. Ensure tun module
log "Checking tun kernel module..."
if ! lsmod | grep -q '^tun'; then
    warn "tun module not loaded, loading now..."
    sudo modprobe tun || { err "Failed to load tun module."; exit 1; }
fi
ok "tun module is loaded."

if [[ ! -e /dev/net/tun ]]; then
    err "/dev/net/tun does not exist."
    exit 1
fi
ok "/dev/net/tun is present."

# 3. Ensure vpnd is running as root
log "Checking vpnd daemon status..."
vpnd_pid_line="$(ps -eo pid,uid,comm | awk '$3 == "vpnd" {print}' | head -n1)"

if [[ -z "$vpnd_pid_line" ]]; then
    warn "vpnd is not running. Starting it as root..."
    sudo "$VPND_BIN" &
    disown
    sleep 1
else
    vpnd_uid="$(awk '{print $2}' <<< "$vpnd_pid_line")"
    if [[ "$vpnd_uid" != "0" ]]; then
        warn "vpnd running as UID $vpnd_uid instead of root. Restarting..."
        sudo pkill vpnd
        sleep 1
        sudo "$VPND_BIN" &
        disown
        sleep 1
    else
        ok "vpnd is already running as root."
    fi
fi

vpnd_pid_line="$(ps -eo pid,uid,comm | awk '$3 == "vpnd" {print}' | head -n1)"
if [[ -z "$vpnd_pid_line" ]]; then
    err "vpnd still isn't running. Aborting."
    exit 1
fi
ok "vpnd confirmed running (pid $(awk '{print $1}' <<< "$vpnd_pid_line"))."

# 4. Warn about conflicting VPN clients
log "Checking for conflicting VPN/tunnel software..."
if command -v warp-cli &>/dev/null; then
    warp_status="$(warp-cli status 2>/dev/null | head -n1)"
    if [[ "$warp_status" == *"Connected"* ]]; then
        warn "Cloudflare WARP is connected — this commonly conflicts with MotionPro."
        read -r -p "    Disconnect it now? [Y/n] " reply
        if [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]; then
            warp-cli disconnect
            ok "WARP disconnected."
        fi
    fi
fi

# 5. Launch the GUI
log "Launching MotionPro GUI..."
export LD_LIBRARY_PATH="/opt/MotionPro:${LD_LIBRARY_PATH:-}"
export LD_PRELOAD="/usr/lib/libstdc++.so.6"
export QT_QPA_PLATFORM="xcb"
unset QT_PLUGIN_PATH
"$MOTIONPRO_BIN" "$@"
```

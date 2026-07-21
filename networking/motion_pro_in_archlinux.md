# Running MotionPro (Array Networks SSL VPN) GUI on Arch Linux — Full Guide

MotionPro is the VPN client for Array Networks' AG (Access Gateway) SSL VPN appliances. Official builds only target Windows, macOS, Ubuntu, RedHat, and CentOS — there's no native Arch package from the vendor. This guide walks through getting it fully working on Arch, based on a real troubleshooting session that hit (and fixed) every common failure point.

## Overview of the process

1. Install MotionPro (via AUR, preferred — or the Ubuntu `.sh` installer as fallback)
2. Fix the daemon (`vpnd`) so it actually starts and runs with the right privileges
3. Fix the GUI's display backend (Qt platform plugin) if it won't launch
4. Configure the connection profile correctly
5. Resolve tunnel/network conflicts with other VPN or DNS-tunneling software

---

## 1. Install MotionPro

### Preferred: install from the AUR

Check first whether it's already packaged:

```bash
yay -S motionpro motionpro-gui
```

This installs proper Arch-native binaries and file locations (typically under `/opt/MotionPro/` and `/usr/bin/MotionPro`), avoiding the packaging mismatches described below.

### Fallback: the vendor's Ubuntu installer

If no AUR package is available for your gateway's client version, you can use the vendor's self-extracting Ubuntu x64 installer (`MotionPro_Linux_Ubuntu_x64.sh`), downloaded from your organization's VPN portal. Be aware it's built assuming a Debian-based system, so parts of it silently fail on Arch — that's expected and fixed in the next section.

```bash
chmod +x MotionPro_Linux_Ubuntu_x64.sh
sudo ./MotionPro_Linux_Ubuntu_x64.sh
```

You'll likely see output like:

```
cp: cannot create regular file '/etc/init.d/': Not a directory
installing vpnd...
installing MotionPro...
creating desktop shortcut for MotionPro...
./install.sh: line 132: update-rc.d: command not found
./install.sh: line 133: service: command not found
install MotionPro successfully.
```

This is normal on Arch. The binaries still get installed correctly — only the Debian-specific service registration (SysV init scripts, `update-rc.d`, `service`) fails, because Arch doesn't have those tools. We fix daemon startup manually in the next step.

> **Note:** Don't run this installer inside a toolbox/distrobox container. VPN clients need to create real `tun` network interfaces and modify host routing tables — something containers isolate by default. Always install and run MotionPro on your actual host system.

---

## 2. Get the `vpnd` daemon running correctly

MotionPro's GUI doesn't talk to the network directly — it hands off tunnel setup to a background daemon called `vpnd`, which needs root privileges to create tunnel interfaces and modify routes. Since the Ubuntu installer's service registration doesn't work on Arch, you need to manage this yourself.

### Check if vpnd is running, and as whom

```bash
ps aux | grep vpnd
```

If it's not listed, or if it's running under a non-root UID (e.g. a dynamic/unprivileged UID rather than `root` or UID `0`), that's a problem — it won't have permission to build the tunnel, and you'll get an error later like *"The MotionPro client fails to configure the L3VPN tunnel."*

### Start (or restart) it explicitly as root

```bash
sudo pkill vpnd        # if an unprivileged instance is already running
sudo /usr/bin/vpnd &   # adjust path if different — check with `which vpnd` or `pacman -Ql motionpro | grep vpnd`
```

Confirm it's now running as root:

```bash
ps aux | grep vpnd
```

### Check the tun kernel module and device

```bash
lsmod | grep tun          # should show the tun module loaded
ls -l /dev/net/tun         # should exist, usually owned by root, mode crw-rw-rw-
sudo modprobe tun          # if the module isn't loaded
```

### (Optional) Make it persistent across reboots

Since there's no working init script, `vpnd` won't restart automatically after a reboot. Create a minimal systemd unit:

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

Then enable it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now vpnd
```

---

## 3. Fix the GUI if it won't launch

Launching `MotionPro` may fail with a Qt platform plugin error, especially on Wayland systems:

```
This application failed to start because it could not find or load the Qt platform plugin "wayland;xcb".
Available platform plugins are: eglfs, linuxfb, minimal, minimalegl, offscreen, xcb.
```

Force it to use the `xcb` plugin (works via XWayland compatibility on virtually all Wayland compositors):

```bash
QT_QPA_PLATFORM=xcb MotionPro
```

If that works and you want it permanent, wrap it in a small launcher script or export the variable in your shell profile before launching MotionPro.

You may also see a harmless line like:

```
/usr/bin/MotionPro: line 9: runlevel: command not found
```

This is just another leftover Debian-ism in the wrapper script — it doesn't affect functionality and can be ignored.

If you additionally see something like:

```
cp: cannot stat '/opt/MotionPro/motionpro.ini': No such file or directory
```

this means a default config file the wrapper script expects is missing (often due to installer conflicts). If the GUI still opens despite the message, you can usually ignore it and proceed to configure your connection profile manually.

---

## 4. Configure the connection profile

When MotionPro opens, it'll ask for connection details. Fill in:

| Field | What to enter |
|---|---|
| **Site Name** | Any label you like — purely local, e.g. `MyOrg VPN` |
| **Host** | `<gateway-ip-or-hostname>:<port>` — e.g. `203.0.113.10:443`. Leave off any alias unless your admin specifically tells you one is required — a made-up alias will cause an *"fails to obtain the AAA method"* error. |
| **Username** | Your VPN account username |
| **Password** | Entered at connect time (leave "Save Password" unchecked unless you want it remembered) |
| **Mode** | `AutoDetect`, unless told otherwise by your admin |

### Troubleshooting the host field

- If you get **"fails to obtain the AAA method"**: this means the client couldn't fetch the gateway's auth configuration before even trying to log in. Check:
  - DNS resolution: `nslookup <hostname>` — confirm it resolves to the expected IP
  - Basic connectivity: `nc -zv <ip> <port>` — confirms the port is reachable
  - Remove any alias you added to the host field unless your admin confirmed one is required
- If you get a straightforward **login failure** after entering credentials: this is a server-side authentication rejection (commonly LDAP-backed). Verify your password is current and your account hasn't been locked or hasn't yet been provisioned for VPN access — check with your VPN admin.

---

## 5. Resolve tunnel conflicts with other VPN/DNS software

If login succeeds but you get:

```
The MotionPro client fails to configure the L3VPN tunnel. Please check your installation.
```

...and `vpnd` is confirmed running as root, the next most common cause is **another VPN or tunneling client already active**, fighting over the same tun interface and routing tables. Common culprits: Cloudflare WARP, other corporate VPN clients, or Tailscale.

Check for and disconnect them, for example with Cloudflare WARP:

```bash
warp-cli disconnect
warp-cli status   # confirm it shows Disconnected / daemon not running
ip a              # confirm no leftover WARP/WireGuard interface remains
```

Then retry connecting in MotionPro.

> **Note:** you generally can't run two full-tunnel VPN clients simultaneously without specific split-tunnel configuration on one or both. If you regularly need both, you'll need to disconnect one before connecting the other each time.

---

## Summary checklist

- [ ] Installed via AUR (preferred) or the Ubuntu `.sh` installer
- [ ] `vpnd` confirmed running **as root**
- [ ] `tun` kernel module loaded, `/dev/net/tun` present
- [ ] GUI launches (use `QT_QPA_PLATFORM=xcb` if needed)
- [ ] Connection profile uses plain `host:port`, no unnecessary alias
- [ ] No conflicting VPN/tunnel software (e.g. Cloudflare WARP) running at connect time
- [ ] (Optional) systemd unit created for `vpnd` so it survives reboots

With all of the above addressed, MotionPro should connect and establish the L3VPN tunnel successfully on Arch Linux.

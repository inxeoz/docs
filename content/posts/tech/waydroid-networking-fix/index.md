---
title: "How to Fix and Automate Waydroid Internet Connectivity on Linux"
date: 2026-07-26
draft: false
tags: ["waydroid", "android", "linux", "networking", "systemd", "lxc"]
categories: ["Tech"]
viewMode: docs
showToc: true
---

Waydroid runs Android inside an LXC container on Linux. It's fast, it's clean, and then you open a browser and nothing loads.

You get `connect: Network is unreachable` or `ping: unknown host`. The Android system boots fine, apps install fine, but the network is dead.

This happens because Waydroid's virtual bridge (`waydroid0`) needs proper IP forwarding, firewall exceptions, and DNS configuration to actually reach the outside world. Here's how to fix it manually, then automate it so you never think about it again.

## The Problem

When Waydroid starts, it creates a virtual network bridge called `waydroid0`. Android connects through this bridge to reach your host's internet. But three things usually go wrong:

1. **IP forwarding is disabled** — your host won't route packets between `waydroid0` and your real interface
2. **Firewall blocks the bridge** — UFW or firewalld drops traffic originating from the container
3. **DNS doesn't inherit** — Android can't see your host's DNS servers

All three need to be fixed. Let's do it.

## Part 1: Quick Fix (Manual Setup)

### Step 1: Enable Kernel IP Forwarding

Waydroid needs your host to forward packets between its bridge and your internet interface.

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

### Step 2: Configure Host Firewall Rules

**For UFW users:**

```bash
# Allow DHCP and DNS traffic on the bridge
sudo ufw allow in on waydroid0 to any port 53 proto udp
sudo ufw allow in on waydroid0 to any port 67 proto udp

# Allow routing and forward policy
sudo ufw allow in on waydroid0
sudo ufw route allow in on waydroid0
sudo ufw default allow FORWARD

# Reload UFW to apply
sudo ufw reload
```

**For Firewalld users:**

```bash
sudo firewall-cmd --zone=trusted --add-interface=waydroid0 --permanent
sudo firewall-cmd --zone=external --add-masquerade --permanent
sudo firewall-cmd --reload
```

### Step 3: Restart the Waydroid Container Service

Restart the LXC container so Waydroid picks up the new routing rules.

```bash
sudo systemctl restart waydroid-container
```

### Step 4: Fix DNS Inside Android

Enter the Waydroid shell and set reliable DNS servers.

```bash
sudo waydroid shell
```

Inside the Android prompt (`:/ #`):

```bash
setprop net.dns1 8.8.8.8
setprop net.dns2 1.1.1.1
```

Test your connection:

```bash
ping -c 3 google.com
```

You should see replies. If you do, the manual fix works. But you don't want to redo this every reboot.

## Part 2: Automating the Process

### Method A: Permanent Host Settings (Systemd & Sysctl)

#### 1. Make IP Forwarding Permanent

Create a persistent sysctl configuration file.

```bash
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-waydroid.conf
sudo sysctl -p /etc/sysctl.d/99-waydroid.conf
```

This survives reboots. The kernel will load this setting on every boot.

#### 2. Make DNS Settings Permanent in Waydroid Config

Append DNS properties into Waydroid's persistent configuration file.

```bash
echo "net.dns1=8.8.8.8" | sudo tee -a /var/lib/waydroid/waydroid.cfg
echo "net.dns2=1.1.1.1" | sudo tee -a /var/lib/waydroid/waydroid.cfg
```

This writes the DNS servers directly into the Waydroid config so Android picks them up on boot.

### Method B: Systemd Auto-Fix Service (Recommended)

Sometimes Android drops its default route or resets DNS properties on startup. A systemd service that runs a fix script after the container starts handles this automatically.

#### 1. Create the Network Fix Helper Script

Create `/usr/local/bin/fix-waydroid-net.sh`:

```bash
#!/bin/bash
# Helper script to ensure Waydroid routing and DNS are active

# Wait for Waydroid session/container to be active
until waydroid status | grep -q "RUNNING"; do
    sleep 2
done

# Ensure DNS properties are set inside Android via ADB
adb shell "setprop net.dns1 8.8.8.8"
adb shell "setprop net.dns2 1.1.1.1"

# Force default route if Android dropped it
adb shell "ip route add default via 192.168.240.1 dev eth0" 2>/dev/null
```

Make it executable.

```bash
sudo chmod +x /usr/local/bin/fix-waydroid-net.sh
```

> The `192.168.240.1` address is Waydroid's default gateway for its `192.168.240.0/24` bridge network. This is the standard Waydroid subnet and does not conflict with most home networks.

#### 2. Create the Systemd Service

Create `/etc/systemd/system/waydroid-net-fix.service`:

```ini
[Unit]
Description=Automated Waydroid Network & DNS Fix
After=waydroid-container.service
Wants=waydroid-container.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fix-waydroid-net.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Enable and start the service.

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now waydroid-net-fix.service
```

Now every time your machine boots, Waydroid starts, the container comes up, and the fix script runs automatically. No manual intervention.

## Troubleshooting

### "Network is unreachable" after reboot

Check if IP forwarding is actually enabled.

```bash
cat /proc/sys/net/ipv4/ip_forward
```

If it returns `0`, the sysctl config didn't apply. Verify `/etc/sysctl.d/99-waydroid.conf` exists and contains `net.ipv4.ip_forward=1`.

### DNS still doesn't work inside Android

The DNS settings might not be reading from `waydroid.cfg`. Try the manual `setprop` method first to confirm DNS works, then check if the config file has a typo.

### Firewall changes don't persist after reboot

UFW rules need `ufw reload` to take effect. Firewalld rules need `--permanent` flag and a `firewall-cmd --reload`. Make sure you added both.

## Summary Checklist

| Component | Setting |
| --- | --- |
| **Host IP Forwarding** | `net.ipv4.ip_forward=1` in `/etc/sysctl.d/99-waydroid.conf` |
| **Firewall Rules** | UFW or firewalld permits `waydroid0` traffic and forwarding |
| **Container DNS** | `net.dns1=8.8.8.8` in `/var/lib/waydroid/waydroid.cfg` |
| **Automation** | Systemd service runs `fix-waydroid-net.sh` after container starts |

---
title: "My Company Only Has an Android VPN App — Here's How I Made It Work on Linux"
date: 2026-07-26
draft: false
tags: ["android", "vpn", "linux", "ssh", "termux", "proxyjump", "development"]
categories: ["Tech"]
viewMode: docs
showToc: true
---

Many organizations only provide VPN access through an Android application like MotionPro. If you develop on Linux, you're stuck — the laptop can't directly access internal company resources.

Instead of fighting the VPN, use the Android phone as a secure SSH jump host. The phone provides VPN connectivity while your Linux laptop keeps its native development environment.

## Architecture

```
                     Company Network
                    (10.0.0.0/8)
                           │
                    MotionPro VPN
                           │
          ┌──────────────────────────┐
          │ Android Phone            │
          │                          │
          │ MotionPro                │
          │ Termux                   │
          │ OpenSSH Server           │
          │ USB Tethering (RNDIS)    │
          └────────────┬─────────────┘
                       │
               USB Network (RNDIS)
             192.168.42.0/24
                       │
          ┌────────────▼─────────────┐
          │ Linux Laptop             │
          │                          │
          │ SSH                      │
          │ rsync                    │
          │ Git                      │
          │ tmux                     │
          └──────────────────────────┘
```

## Why This Works

- No rooting required
- No VPN installation on Linux
- No company configuration changes
- Native Linux development
- Works with SSH, rsync, Git, tmux, SCP, SFTP, and VS Code Remote SSH
- Portable

## Step 1: Install OpenSSH in Termux

On your Android phone:

```sh
pkg update
pkg install openssh
```

Generate host keys (first run only):

```sh
ssh-keygen -A
```

Start SSH:

```sh
sshd
```

Verify:

```sh
ss -tln
```

Expected:

```
LISTEN 0 128 0.0.0.0:8022
```

Find the Termux username:

```sh
whoami
```

Example output:

```
u0_a123
```

## Step 2: Enable USB Tethering

On your phone, enable:
- USB Debugging
- USB Tethering

On your laptop, find the USB interface:

```bash
ip addr
```

Example:

```
enp0s20f0u2
192.168.42.136/24
```

On your phone (in Termux):

```sh
ifconfig
```

Example:

```
rndis0
192.168.42.123/24
```

Test connectivity:

```sh
ping 192.168.42.136
```

## Step 3: Connect ADB

On your laptop:

```bash
adb start-server
adb devices
```

Expected:

```
List of devices attached
XXXXXXXX device
```

Forward SSH port:

```bash
adb forward tcp:8022 tcp:8022
```

Test:

```bash
ssh -p 8022 u0_a123@127.0.0.1
```

## Step 4: Connect MotionPro

Launch MotionPro on your phone and authenticate.

Verify inside Termux that you can reach the company network:

```sh
ssh demo_user@10.0.50.10
```

If this works, the phone can already reach the company network.

## Step 5: Configure SSH ProxyJump

Create `~/.ssh/config` on your laptop:

```
Host termux
    HostName 127.0.0.1
    Port 8022
    User u0_a123

Host office
    HostName 10.0.50.10
    User demo_user
    ProxyJump termux

    ServerAliveInterval 30
    ServerAliveCountMax 3

    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 10m
```

Now simply run:

```bash
ssh office
```

Behind the scenes:

```
Laptop
   │
   ▼
127.0.0.1:8022
   │
   ▼
Termux
   │
MotionPro VPN
   │
   ▼
Company Server
```

## Step 6: rsync

Upload:

```bash
rsync -avz --delete \
    --exclude='.git/' \
    --exclude='node_modules/' \
    --exclude='__pycache__/' \
    ~/Work/my-project/app/ \
    office:/home/demo_user/project/app/
```

Download:

```bash
rsync -avz \
    office:/home/demo_user/project/data/ \
    ~/Downloads/project-data/
```

## Step 7: SCP

Upload:

```bash
scp file.txt office:/tmp/
```

Download:

```bash
scp office:/tmp/file.txt .
```

## Step 8: Git

Clone:

```bash
git clone office:/home/demo_user/project.git
```

Push:

```bash
git push
```

Everything uses the SSH configuration automatically.

## Step 9: tmux Workflow

```bash
ssh office
tmux new -A -s work
```

Continue working exactly where you left off.

## Step 10: Automation

Create `company-connect`:

```bash
#!/usr/bin/env bash
set -euo pipefail

adb start-server >/dev/null
adb wait-for-device
adb forward tcp:8022 tcp:8022 >/dev/null 2>&1 || true

exec ssh office
```

Create `company-sync`:

```bash
#!/usr/bin/env bash
set -euo pipefail

adb start-server >/dev/null
adb wait-for-device
adb forward tcp:8022 tcp:8022 >/dev/null 2>&1 || true

rsync -avz --delete \
    --exclude='.git/' \
    --exclude='node_modules/' \
    --exclude='__pycache__/' \
    ~/Work/my-project/app/ \
    office:/home/demo_user/project/app/
```

## Why We Didn't Use SSHFS

`sshfs` is currently unavailable in Termux, and even if it were, Android's FUSE limitations make it an unreliable foundation for this workflow.

Using SSH, rsync, Git, and tmux provides a more robust and portable setup.

## Why We Didn't Route the Entire Subnet Through Android

A true transparent gateway would require Android to:
- Enable IP forwarding
- Forward traffic between `rndis0` and the VPN interface (`tun0`)
- Perform NAT (masquerading)

These operations require root privileges on Android. Without root, stock Android cannot act as a full IP router for your laptop.

SSH ProxyJump achieves the desired development workflow without requiring those capabilities.

## Summary

This solution transforms an Android phone into a VPN-enabled SSH bastion for a Linux laptop. The phone provides secure access to the corporate network, while the laptop retains its native development environment and tools.

The result is a practical workflow that supports SSH, rsync, SCP, Git over SSH, tmux, and remote development — without rooting the phone or modifying the corporate VPN infrastructure.

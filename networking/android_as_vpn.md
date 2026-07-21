# Android VPN Gateway for Linux Development Using Termux, ADB, SSH ProxyJump, and rsync

## Introduction

Many organizations only provide VPN access through an Android application such as **MotionPro**. This makes it difficult to use a Linux laptop for development because the laptop cannot directly access internal company resources.

Instead of running the VPN on Linux, we can use the Android phone as a secure SSH jump host.

The result is a development workflow where the phone provides VPN connectivity while the Linux laptop continues to use its native development environment.

---

# Architecture

```
                     Company Network
                    (172.18.0.0/16)
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
             10.161.121.0/24
                       │
          ┌────────────▼─────────────┐
          │ Arch Linux Laptop        │
          │                          │
          │ SSH                      │
          │ rsync                    │
          │ Git                      │
          │ tmux                     │
          │ Neovim                   │
          └──────────────────────────┘
```

---

# Why This Architecture?

Advantages:

* No rooting required.
* No VPN installation on Linux.
* No company configuration changes.
* Native Linux development.
* Works with SSH, rsync, Git, tmux, SCP, SFTP, and VS Code Remote SSH.
* Portable.

---

# Step 1 — Install OpenSSH in Termux

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

Example:

```
u0_a414
```

---

# Step 2 — Enable USB Tethering

Enable:

* USB Debugging
* USB Tethering

Laptop:

```bash
ip addr
```

Example:

```
enp0s20f0u2
10.161.121.136/24
```

Phone:

```sh
ifconfig
```

Example:

```
rndis0
10.161.121.123/24
```

Connectivity test:

```sh
ping 10.161.121.136
```

---

# Step 3 — Connect ADB

Laptop:

```bash
adb start-server
adb devices
```

Expected:

```
List of devices attached
XXXXXXXX device
```

Forward SSH:

```bash
adb forward tcp:8022 tcp:8022
```

Test:

```bash
ssh -p 8022 u0_a414@127.0.0.1
```

---

# Step 4 — Connect MotionPro

Launch MotionPro.

Authenticate.

Verify inside Termux:

```sh
ssh inxeoz@172.18.210.49
```

If this works, the phone can already reach the company network.

---

# Step 5 — Configure SSH ProxyJump

Create:

```
~/.ssh/config
```

```
Host termux
    HostName 127.0.0.1
    Port 8022
    User u0_a414

Host office
    HostName 172.18.210.49
    User inxeoz
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

---

# Step 6 — rsync

Upload:

```bash
rsync -avz --delete \
    --exclude='.git/' \
    --exclude='node_modules/' \
    --exclude='__pycache__/' \
    --exclude='*.pyc' \
    /home/inxeoz/Work/tries/2026-06-29-extend-alis/bench-extend/apps/alis/ \
    office:/home/inxeoz/pro/apps/alis/
```

Download:

```bash
rsync -avz \
    office:/home/inxeoz/pro/apps/alis/ \
    ~/Downloads/alis/
```

---

# Step 7 — SCP

Upload:

```bash
scp file.txt office:/tmp/
```

Download:

```bash
scp office:/tmp/file.txt .
```

---

# Step 8 — Git

Clone:

```bash
git clone office:/home/inxeoz/project.git
```

Push:

```bash
git push
```

Everything uses the SSH configuration automatically.

---

# Step 9 — tmux Workflow

```
ssh office
tmux new -A -s work
```

Continue working exactly where you left off.

---

# Step 10 — Automation

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
    --exclude='*.pyc' \
    /home/inxeoz/Work/tries/2026-06-29-extend-alis/bench-extend/apps/alis/ \
    office:/home/inxeoz/pro/apps/alis/
```

---

# Why We Didn't Use SSHFS

`sshfs` is currently unavailable in Termux, and even if it were, Android's FUSE limitations make it an unreliable foundation for this workflow.

Using SSH, rsync, Git, and tmux provides a more robust and portable setup.

---

# Why We Didn't Route 172.18.0.0/16 Through Android

A true transparent gateway would require Android to:

* Enable IP forwarding.
* Forward traffic between `rndis0` and the VPN interface (`tun0`).
* Perform NAT (masquerading).

These operations require root privileges on Android.

Without root, stock Android cannot act as a full IP router for your laptop.

SSH ProxyJump achieves the desired development workflow without requiring those capabilities.

---

# Future Improvements

* Passwordless SSH with public keys.
* Automatically start `sshd` in Termux.
* Automatically establish the MotionPro VPN.
* Wrapper commands for `ssh`, `rsync`, and `scp`.
* SSH multiplexing for faster reconnects.
* Replace the physical phone with an Android VM (such as Genymotion) if MotionPro works correctly in the emulator.

---

# Summary

This solution transforms an Android phone into a VPN-enabled SSH bastion for a Linux laptop.

The phone provides secure access to the corporate network, while the laptop retains its native development environment and tools.

The result is a practical workflow that supports:

* SSH
* rsync
* SCP
* Git over SSH
* tmux
* Remote development

without rooting the phone or modifying the corporate VPN infrastructure.

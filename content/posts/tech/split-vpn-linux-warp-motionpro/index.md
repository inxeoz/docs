---
title: "How to Run Cloudflare WARP and a Corporate VPN Simultaneously on Linux"
date: 2026-07-26
draft: false
tags: ["vpn", "cloudflare", "warp", "motionpro", "linux", "routing", "split-tunnel"]
categories: ["Tech"]
viewMode: docs
showToc: true
---

Modern Linux systems often need to run multiple VPNs at the same time. A common setup: Cloudflare WARP for secure internet access and an enterprise VPN (Array Networks / MotionPro) for internal company servers, where only specific internal IPs should go through the enterprise VPN.

## What We're Solving

| Traffic | Route |
|---------|-------|
| Internet | Cloudflare WARP |
| Internal server (10.0.50.10) | MotionPro VPN |
| Everything else | Unchanged |

## Environment Overview

### VPNs

- **Enterprise VPN**: Array Networks / Ivanti MotionPro
  - CLI: `vpn_cmdline`
  - Tunnel interface: `tun0`
- **External VPN**: Cloudflare WARP
  - Interface: `CloudflareWARP`
  - Uses policy routing

### Target

- Internal SSH server: `10.0.50.10`

## Part 1: Connecting to MotionPro on Linux

### Installation (Arch Linux)

```bash
yay -S motionpro
```

Verify:

```bash
which vpn_cmdline
# /usr/bin/vpn_cmdline
```

### Host Format

`vpn_cmdline` expects:

```
<gateway_host>[/alias]
```

Do NOT use `https://`, browser URLs, `/login/index.html`, or `/prx/000/http/...`.

Correct examples:

```text
vpn.example.com
vpn.example.com/employee
198.51.100.10
198.51.100.10/demo
```

### Basic Connection

```bash
sudo vpn_cmdline \
  -h 198.51.100.10 \
  -u demo_user \
  -p 'your_password'
```

Successful output:

```
login successfully!
starting vpn......
connect successfully!
vpn is running...
```

### Authentication Method (if required)

Some gateways require specifying the auth backend:

```bash
sudo vpn_cmdline \
  -h 198.51.100.10 \
  -u demo_user \
  -p 'your_password' \
  -m LDAP_METHOD
```

### Safer Password Handling

```bash
read -s VPN_PASS
sudo vpn_cmdline -h 198.51.100.10 -u demo_user -p "$VPN_PASS"
unset VPN_PASS
```

### Verify VPN Tunnel

```bash
ip addr | grep tun0
```

Expected:

```
tun0 ... inet 192.168.x.x peer 1.1.1.1
```

### Disconnecting

```bash
sudo vpn_cmdline --stop
```

## Part 2: Understanding the Routing Conflict

### Why SSH Doesn't Work Initially

Check how traffic to the internal server is routed:

```bash
ip route get 10.0.50.10
```

Problematic output:

```
10.0.50.10 via 1.1.1.1 dev CloudflareWARP src 172.16.0.2
```

This means Cloudflare WARP captured the traffic. MotionPro never sees the packets. SSH hangs or times out.

### Why This Happens

Cloudflare WARP uses its own routing table, policy routing (`ip rule`), and high-priority rules that override normal routes. Because of this, `ip route add` alone is not enough — we must override both routing and policy.

## Part 3: Routing a Specific IP Through MotionPro

### Step 1: Replace the Route

```bash
sudo ip route replace 10.0.50.10/32 dev tun0
sudo ip route flush cache
```

Verify:

```bash
ip route get 10.0.50.10
```

Expected:

```
10.0.50.10 dev tun0 src 192.168.x.x
```

### Step 2: Override WARP Policy Routing

Check policy rules:

```bash
ip rule
```

Typical output includes:

```
1000: from all lookup warp
```

### Step 3: Add a Higher-Priority Policy Rule

```bash
sudo ip rule add to 10.0.50.10/32 lookup main priority 100
sudo ip route flush cache
```

Verify again:

```bash
ip route get 10.0.50.10
```

Now traffic flows through `tun0`.

### Step 4: Test SSH

```bash
ssh demo_user@10.0.50.10
```

If it connects, routing is correct and VPN coexistence is successful.

## Part 4: Optional Enhancements

### Routing an Entire Subnet

```bash
sudo ip route replace 10.0.0.0/8 dev tun0
sudo ip rule add to 10.0.0.0/8 lookup main priority 100
sudo ip route flush cache
```

### Make It Persistent

```bash
sudo nano /usr/local/bin/motionpro-split-routing.sh
```

```bash
#!/bin/bash
ip route replace 10.0.50.10/32 dev tun0
ip rule add to 10.0.50.10/32 lookup main priority 100 || true
ip route flush cache
```

```bash
sudo chmod +x /usr/local/bin/motionpro-split-routing.sh
```

## Key Takeaways

- Multiple VPNs can coexist on Linux
- Cloudflare WARP uses policy routing
- `/32` host routes are precise and safe
- `ip route replace` > `ip route add`
- `ip rule` enables deterministic control
- WARP never had to be disabled

## Final Architecture

```
Internet traffic        → Cloudflare WARP
10.0.50.10 (SSH)        → MotionPro VPN (tun0)
Everything else         → unchanged
```

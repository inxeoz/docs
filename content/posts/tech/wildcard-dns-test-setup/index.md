---
title: "How to Set Up *.test Domains Locally Without Breaking Your DNS"
date: 2026-07-26
draft: false
tags: ["dns", "dnsmasq", "systemd-resolved", "linux", "development", "networking"]
categories: ["Tech"]
viewMode: docs
showToc: true
---

Local development environments often need custom domains like `myapp.test`, `api.test`, or `backend.internal.test`. But wildcard resolution (`*.test → 127.0.0.1`) is tricky.

Most tutorials break DNS by:
- Overwriting `/etc/resolv.conf`
- Disabling systemd-resolved
- Hijacking port 53
- Interfering with libvirt DNS
- Using `.local` (reserved for mDNS)

This article walks through the correct, safe, reversible approach using dnsmasq on a separate port with systemd-resolved split DNS routing.

## Goal

We want `*.test → 127.0.0.1` without breaking system DNS, VPN DNS, libvirt/QEMU DNS, or systemd-resolved.

The solution must be wildcard-capable, isolated, non-conflicting, and 100% reversible.

## Step 1: Create a Dedicated dnsmasq Instance on Port 5353

```bash
sudo mkdir -p /etc/dnsmasq.d-test
sudo nano /etc/dnsmasq.d-test/test.conf
```

Add:

```ini
# dnsmasq for .test wildcard resolution
port=5353
bind-interfaces
listen-address=127.0.0.1

# Wildcard domain rule
address=/.test/127.0.0.1
```

This ensures dnsmasq never conflicts with system services.

## Step 2: Create a Systemd Service

```bash
sudo nano /etc/systemd/system/dnsmasq-test.service
```

Add:

```ini
[Unit]
Description=Dnsmasq Instance for .test Wildcard Resolution
After=network.target

[Service]
ExecStart=/usr/bin/dnsmasq --keep-in-foreground --conf-dir=/etc/dnsmasq.d-test
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now dnsmasq-test
```

Verify:

```bash
systemctl status dnsmasq-test
```

## Step 3: Verify dnsmasq Answers .test Queries

```bash
dig @127.0.0.1 -p 5353 hello.test
```

Should return:

```
hello.test.  0  IN A  127.0.0.1
```

## Step 4: Configure systemd-resolved Split DNS

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo nano /etc/systemd/resolved.conf.d/10-test-domain.conf
```

Add:

```ini
[Resolve]
DNS=127.0.0.1:5353
Domains=~test
```

This means:
- Only `.test` domains go to dnsmasq-test
- All other domains go through your normal DNS

Reload:

```bash
sudo systemctl restart systemd-resolved
```

## Step 5: Test Wildcard Resolution

```bash
resolvectl query hello.test
resolvectl query anything.test
resolvectl query backend.internal.test
```

You should always get `127.0.0.1`.

Test in browser:

```
http://myapp.test
```

This resolves cleanly without modifying `/etc/hosts`.

## Why This Works

systemd-resolved acts as the system DNS interceptor. When you add:

```
Domains=~test
DNS=127.0.0.1:5353
```

You instruct resolved to forward ONLY `.test` queries to dnsmasq-test, and ignore upstream DNS servers for these queries.

dnsmasq-test uses `address=/.test/127.0.0.1`, so any `.test` domain — regardless of subdomain depth — returns `127.0.0.1`.

| Domain | Resolver | Output |
|--------|----------|--------|
| hello.test | dnsmasq-test | 127.0.0.1 |
| api.backend.test | dnsmasq-test | 127.0.0.1 |
| google.com | upstream DNS | real IP |
| archlinux.org | upstream DNS | real IP |

No conflict. No breakage. No override of system functions.

## How to Remove the Configuration

100% rollback, safe.

### 1. Remove dnsmasq-test config and disable service

```bash
sudo systemctl disable --now dnsmasq-test
sudo rm -r /etc/dnsmasq.d-test
sudo rm /etc/systemd/system/dnsmasq-test.service
sudo systemctl daemon-reload
```

### 2. Remove split-DNS rule from systemd-resolved

```bash
sudo rm /etc/systemd/resolved.conf.d/10-test-domain.conf
sudo systemctl restart systemd-resolved
```

### 3. Verify cleanup

```bash
resolvectl domain
resolvectl dns
```

Ensure `.test` no longer appears in routing.

### 4. Test

```bash
resolvectl query hello.test
```

Should now return `Failed to resolve …`.

## Summary

This method is:
- Modern and robust
- systemd-compatible
- Container-friendly
- VPN-friendly
- Zero-conflict
- Wildcard-capable
- Fully reversible

It's the safest way on modern Linux to get `.test` (or `.dev`, `.lab`, `.localtest`) wildcard DNS resolution — perfect for Frappe, Docker, local microservices, and web dev environments.

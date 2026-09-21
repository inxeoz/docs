---
title: "NGINX in Front of Traefik: Enterprise Frappe Deployments on RHEL"
date: 2026-07-26
draft: false
tags: ["nginx", "traefik", "frappe", "reverse-proxy", "selinux", "firewalld", "enterprise"]
categories: ["Tech"]
viewMode: docs
showToc: true
---

In restricted enterprise environments (VPN-only, SELinux enforcing, firewalld enabled), applications are often exposed on non-standard ports like `:8100`. This works but leads to poor user experience, security concerns, and scalability limitations.

This article documents a multi reverse proxy architecture that exposes applications using hostnames only, without leaking internal ports, while keeping all security controls enabled.

## Target Architecture

```
Client (VPN)
   |
   | http://site-a.example.com
   |
NGINX (host :80)
   |
   | proxy_pass http://127.0.0.1:8100
   v
Traefik (Docker reverse proxy)
   |
   v
Frappe (site routing by Host header)
```

## Components and Roles

**NGINX** — Front door. Listens on port 80, routes by hostname.

**Traefik** — Service router. Runs in Docker, routes to correct container.

**Frappe / ERPNext** — Application router. Selects site based on HTTP `Host` header.

> NGINX decides WHERE. Traefik decides WHICH service. Frappe decides WHICH site.

## Pre-Conditions (Mandatory)

Do NOT proceed unless all of the following are true.

### 1. VPN Connectivity Works

From the client machine:

```bash
ping 10.0.50.10
```

Expected: replies received, no packet loss.

### 2. Hostname Resolution Exists

From VPN client:

```bash
ping site-a.example.com
ping site-b.example.com
```

If DNS is not available, `/etc/hosts` must already contain:

```
10.0.50.10   site-a.example.com
10.0.50.10   site-b.example.com
```

### 3. Traefik Already Works by Host Header

From the server:

```bash
curl -H "Host: site-a.example.com" http://127.0.0.1:8100
```

Expected: `HTTP/1.1 200 OK` with Frappe HTML output.

If this fails, Traefik/Frappe must be fixed first.

### 4. Frappe Sites Already Exist

```bash
bench --site site-a.example.com list-apps
bench --site site-b.example.com list-apps
```

### 5. NGINX Is Running on Port 80

```bash
ss -tulnp | grep ':80 '
```

Expected:

```
users:(("nginx",pid=...))
```

## Implementation

### Step 1: Backup NGINX Configuration

```bash
cp -a /etc/nginx /root/nginx-backup-$(date +%F-%H%M)
```

### Step 2: Add NGINX Server Block

```bash
vim /etc/nginx/conf.d/frappe-proxy.conf
```

```nginx
server {
    listen 80;
    server_name site-a.example.com site-b.example.com;

    location / {
        proxy_pass http://127.0.0.1:8100;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```

### Step 3: Validate Configuration

```bash
nginx -t
```

Expected:

```
syntax is ok
test is successful
```

### Step 4: Reload NGINX

```bash
systemctl reload nginx
```

## SELinux Requirement (RHEL)

On RHEL / Rocky / Alma:

```bash
getenforce
# Expected: Enforcing
```

Enable outbound proxy connections without disabling SELinux:

```bash
setsebool -P httpd_can_network_connect on
```

## Firewall Requirement

Confirm port 80 is allowed:

```bash
firewall-cmd --list-ports | grep 80
```

If missing:

```bash
firewall-cmd --add-port=80/tcp
firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --reload
```

## Verification

### Server-Side Test

```bash
curl -H "Host: site-a.example.com" http://127.0.0.1
```

Expected: `200 OK` with Frappe HTML.

### Client-Side Test (VPN)

In browser:

```
http://site-a.example.com
http://site-b.example.com
```

Expected: no port in URL, correct Frappe site loads.

## Common Failure Modes

### 502 Bad Gateway

Check SELinux:

```bash
getenforce
setsebool -P httpd_can_network_connect on
```

Check logs:

```bash
journalctl -u nginx --no-pager | tail
```

### Works on server but not client

Check firewall:

```bash
firewall-cmd --list-ports
```

Check VPN routing:

```bash
ping 10.0.50.10
```

### Traefik works on `:8100` but not via NGINX

Confirm backend reachability:

```bash
curl http://127.0.0.1:8100
curl -H "Host: site-a.example.com" http://127.0.0.1:8100
```

## Security Posture (Final State)

| Layer | Status |
|-------|--------|
| SELinux | Enforcing |
| firewalld | Enabled |
| VPN | Required |
| Docker | Isolated |
| App ports | Hidden |

## Conclusion

A multi reverse proxy is not complexity — it is correct separation of concerns. This design removes port exposure, preserves security controls, scales cleanly to many subdomains, and works fully inside VPN-only environments.

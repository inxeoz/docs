---
title: "Swapping Large or Stalled Files with mitmproxy"
date: 2026-06-01
draft: false
viewMode: docs
tags: ["mitmproxy", "proxy", "debugging", "networking", "tools"]
categories: ["Tech"]
showToc: true
---

You're on a slow network, the JS bundle is 16 MB, and your page won't finish loading. Or a CDN returns a 504 every third request. You already have the file locally — you just need the browser to use *that* instead of fetching it again.

**mitmproxy** can intercept the specific request and swap in a local file transparently. The server never knows, the browser never knows, and the page loads instantly.

## When to Swap

- **Oversized assets** — analytics SDKs, heavy JS bundles, fonts, 4K images
- **Stalled/CDN issues** — remote server is slow or intermittent
- **Offline development** — work without internet, serve cached files
- **Experiments** — tweak a remote file and test immediately without deploying

## The Proxy Setup

Install mitmproxy:

```bash
pip install mitmproxy
# or: pacman -S mitmproxy  # Arch
# or: brew install mitmproxy
```

## The Inline Script

Create `inline_cache.py`:

```python
from mitmproxy import http

def request(flow: http.HTTPFlow) -> None:
    # Match the URL (or a unique substring)
    if "main.ccc87319f78e3f77.js" in flow.request.pretty_url:
        with open("/path/to/local/main.ccc87319f78e3f77.js", "rb") as f:
            flow.response = http.Response.make(
                200,
                f.read(),
                {"Content-Type": "application/javascript"}
            )
```

Matching can use any part of the URL — the hash, the path, the domain. Add more `if` blocks to swap multiple files.

## Run mitmdump

```bash
mitmdump -s inline_cache.py --mode regular@8099
```

- `-s` loads the inline script
- `--mode regular@8099` listens as an HTTP proxy on port 8099

## Launch the Browser

```bash
chromium --proxy-server="127.0.0.1:8099" \
         --ignore-certificate-errors \
         --user-data-dir=/tmp/proxied-profile
```

- `--proxy-server` routes all traffic through mitmproxy
- `--ignore-certificate-errors` skips CA warnings (mitmproxy generates its own cert)
- `--user-data-dir` uses a fresh profile so no extensions interfere

Now visit the target site — the matched file is served from disk instantly.

## Common Pitfall: SSL Legacy Renegotiation

Some ancient servers (government portals, legacy banking, embedded devices) try SSL renegotiation, which OpenSSL 3.x blocks by default:

```
OpenSSL Error: unsafe legacy renegotiation disabled
```

mitmproxy has a built-in fix — the `ssl_insecure` option:

```bash
mitmdump -s inline_cache.py --mode regular@8099 \
         --set ssl_insecure=true
```

Inside mitmproxy, this sets `SSL_OP_LEGACY_SERVER_CONNECT` on the upstream SSL context (`mitmproxy/net/tls.py:234`):

```python
if legacy_server_connect:
    context.set_options(OP_LEGACY_SERVER_CONNECT)
```

## Full Working Example

Putting it all together:

```bash
# Terminal 1 — proxy
mitmdump -s inline_cache.py --mode regular@8099 \
         --set connection_strategy=lazy \
         --set ssl_insecure=true

# Terminal 2 — browser
chromium --proxy-server="127.0.0.1:8099" \
         --ignore-certificate-errors \
         --user-data-dir=/tmp/proxied-profile
```

`inline_cache.py`:

```python
from mitmproxy import http

def request(flow: http.HTTPFlow) -> None:
    if "main.ccc87319f78e3f77.js" in flow.request.pretty_url:
        with open("/home/user/cache/main.ccc87319f78e3f77.js", "rb") as f:
            flow.response = http.Response.make(
                200,
                f.read(),
                {"Content-Type": "application/javascript"}
            )
```

## Advanced: Swap Multiple Files

```python
import json
from pathlib import Path
from mitmproxy import http

LOCAL_DIR = "/home/user/cache"
SWAP_RULES = {
    "bundle.js":      "application/javascript",
    "logo.svg":       "image/svg+xml",
    "data.json":      "application/json",
    "font.woff2":     "font/woff2",
}

def request(flow: http.HTTPFlow) -> None:
    for filename, mime in SWAP_RULES.items():
        if filename in flow.request.pretty_url:
            path = Path(LOCAL_DIR) / filename
            if path.exists():
                flow.response = http.Response.make(
                    200, path.read_bytes(),
                    {"Content-Type": mime}
                )
            break
```

## Why Debuggers & Tech-Savvy Users Love This

### 1. Patch Broken CDNs Instantly

A CDN goes down, a dependency 404s, or CORS blocks local dev — swap the failing asset with a working copy and move on.

### 2. Test Error States That Are Hard to Reproduce

Return 500s, timeouts, or malformed JSON to see how your frontend handles failure:

```python
def request(flow: http.HTTPFlow) -> None:
    if "/api/checkout" in flow.request.pretty_url:
        flow.response = http.Response.make(
            500, b'{"error":"service unavailable"}',
            {"Content-Type": "application/json"}
        )
```

### 3. Slow Down Responses for Loading State Testing

Artificially delay specific assets:

```python
import time

def request(flow: http.HTTPFlow) -> None:
    if "hero-image.jpg" in flow.request.pretty_url:
        time.sleep(8)  # simulate slow network
```

### 4. Audit What a Page Actually Loads

Log every request to find bloat, tracking pixels, or unexpected calls:

```python
def request(flow: http.HTTPFlow) -> None:
    print(f"[{flow.request.method}] {flow.request.pretty_url}  ->  {len(flow.request.content)} bytes")
```

### 5. Modify Server Responses Without a Backend

Tweak API output, swap translations, change feature flags — all client-side, no backend deploy needed:

```python
def response(flow: http.HTTPFlow) -> None:
    if "/api/config" in flow.request.pretty_url:
        text = flow.response.text()
        text = text.replace('"experimental":false', '"experimental":true')
        flow.response.text = text
```

### 6. Work Offline

Cache every asset once, then disconnect. The proxy serves the local copies — ideal for trains, planes, or bad hotel Wi-Fi.

### 7. Reverse-Engineer API Contracts

Capture exactly what requests a mobile app or SPA makes, in what order, with what payloads. No need for network tab — mitmproxy logs everything to a file or terminal.

## Security Risks — What an Attacker Can Do

mitmproxy is a **transparent TLS-intercepting proxy**. The same mechanics that let you swap a JS file for debugging let an attacker swap *anything*.

### 1. Script Injection

Swap any `.js` file to inject keyloggers, session stealers, or crypto miners:

```python
def request(flow: http.HTTPFlow) -> None:
    if "analytics.js" in flow.request.pretty_url:
        flow.response = http.Response.make(
            200,
            b'document.body.innerHTML = "<h1>PWNED</h1>";',
            {"Content-Type": "application/javascript"}
        )
```

### 2. Login Page Phishing

Swap an HTML response and capture credentials:

```python
def request(flow: http.HTTPFlow) -> None:
    if "login" in flow.request.pretty_url:
        with open("fake_login.html") as f:
            flow.response = http.Response.make(
                200, f.read().encode(),
                {"Content-Type": "text/html"}
            )
```

The fake page submits credentials to the attacker's server.

### 3. SSL/TLS Bypass

`--set ssl_insecure=true` disables certificate verification entirely. With `--ignore-certificate-errors` in the browser, there is **zero cryptographic protection** — the attacker's word is the law.

### 4. API Response Tampering

Modify JSON/API responses to bypass client-side checks, elevate privileges, or inject malicious data:

```python
def response(flow: http.HTTPFlow) -> None:
    if "/api/user" in flow.request.pretty_url:
        data = json.loads(flow.response.text())
        data["role"] = "admin"
        data["verified"] = True
        flow.response.text = json.dumps(data)
```

### 5. Silent Persistence

A compromised proxy can rewrite update/upgrade URLs to serve backdoored binaries:

```python
if "update.example.com/package.deb" in flow.request.pretty_url:
    flow.response = http.Response.make(
        200, open("backdoored.deb", "rb").read(),
        {"Content-Type": "application/octet-stream"}
    )
```

### Defensive Measures

| Risk | Mitigation |
|------|------------|
| Rogue proxy on network | Use HTTPS with **certificate pinning** (HPKP, Certificate Transparency) |
| User-installed CA | Never install untrusted CA certificates; audit your trust store regularly |
| System-wide proxy | Block unexpected proxy config via Group Policy / MDM |
| Transparent proxy | Use **DNS-over-HTTPS** + **TLS 1.3 Encrypted ClientHello** to hide SNI |
| MitM detection | Apps can call `SSLContext.get_ca_certs()` to detect unknown CAs |

**Bottom line**: mitmproxy is a double-edged sword. It's indispensable for debugging, but in the wrong hands it's a full man-in-the-middle toolkit. Never leave a mitmproxy instance running on a network you don't control.

## Summary

| Step | Command |
|------|---------|
| Start proxy | `mitmdump -s script.py --mode regular@8099 --set ssl_insecure=true` |
| Open browser | `chromium --proxy-server="127.0.0.1:8099" --ignore-certificate-errors --user-data-dir=/tmp/proxied-profile` |
| Match & swap | `if "filename" in flow.request.pretty_url: flow.response = http.Response.make(...)` |

mitmproxy turns a slow, network-bound page into a local-first experience in under 20 lines of Python.

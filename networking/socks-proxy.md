# How to Use python3-pysocks: A Complete Guide

**python3-pysocks** is a Python SOCKS client module that enables Python applications to route network traffic through SOCKS4 and SOCKS5 proxies. It's particularly valuable in enterprise environments where direct internet access is restricted and a proxy is required for package installations and network operations .

## What is PySocks?

PySocks is a fork of SocksiPy with bug fixes and additional features. It acts as a drop-in replacement for Python's standard `socket` module, allowing you to seamlessly route connections through a proxy .

Key features include:

- SOCKS proxy client for Python 2.6 through 3.x
- Support for both TCP and UDP protocols
- HTTP proxy client included
- urllib2 handler included 

## Installation

### Method 1: Install via YUM (Recommended for RHEL/CentOS/Rocky/AlmaLinux)

On Enterprise Linux systems, installing the native RPM package is the most reliable approach, especially when you need to bootstrap proxy support without existing internet access .

```bash
sudo yum install python3-pysocks
```

This installs the version bundled with your distribution. For RHEL 9 and compatible systems, this is typically version 1.7.1 .

### Method 2: Install via pip

If you already have working proxy support or direct internet access, use pip:

```bash
pip install PySocks
```

Or for a specific Python version:

```bash
python3.11 -m pip install PySocks
```

### Method 3: Offline Installation

When your server has no internet access and pip fails due to missing SOCKS dependencies, you can bootstrap PySocks from the RPM package :

```bash
# Install the RPM
sudo yum install python3-pysocks

# Locate the installed socks module
rpm -ql python3-pysocks | grep socks.py

# Copy it to your target Python version's site-packages
mkdir -p ~/.local/lib/python3.11/site-packages
cp $(rpm -ql python3-pysocks | grep '/socks.py$') ~/.local/lib/python3.11/site-packages/
```

Verify the installation:

```bash
python3.11 -c "import socks; print(socks.__version__)"
```

## Using PySocks in Your Python Code

### Basic SOCKS5 Proxy Setup

The simplest way to use PySocks is to replace the default socket with a proxy-aware socket :

```python
import socks
import socket

# Configure the SOCKS5 proxy
socks.set_default_proxy(socks.SOCKS5, "127.0.0.1", 9050)

# Replace the default socket
socket.socket = socks.socksocket

# All subsequent connections will use the proxy
try:
    print(socket.gethostbyname("example.com"))
except Exception as e:
    print(f"Error: {e}")
```

### Using SOCKS5 with Remote DNS Resolution

For environments where DNS must also be resolved through the proxy (common in restricted networks), use `socks5h` which forces hostname resolution through the proxy :

```python
import socks
import socket

socks.set_default_proxy(socks.SOCKS5, "127.0.0.1", 19052)
socket.socket = socks.socksocket
```

### Proxy Authentication

If your proxy requires authentication :

```python
import socks

socks.set_default_proxy(
    socks.SOCKS5,
    "proxy.example.com",
    1080,
    username="your_username",
    password="your_password"
)
```

### Integrating with the Requests Library

PySocks works seamlessly with popular HTTP libraries like `requests` :

```python
import requests
import socks
import socket

# Configure proxy
socks.set_default_proxy(socks.SOCKS5, "localhost", 9050)
socket.socket = socks.socksocket

# Make requests through the proxy
response = requests.get("https://example.com")
print(response.status_code)
```

## Configuring pip to Use SOCKS Proxy

When working behind a SOCKS proxy, pip needs PySocks installed to function. You can configure pip globally to use your proxy :

Create or edit `~/.config/pip/pip.conf`:

```ini
[global]
proxy = socks5h://127.0.0.1:19052
```

This configuration ensures all pip commands automatically route through the proxy once PySocks is installed .

## Troubleshooting Common Issues

### "Missing dependencies for SOCKS support" Error

This error occurs when pip detects a SOCKS proxy in your environment variables but PySocks isn't installed. The paradox: pip needs PySocks to use the proxy, but can't install PySocks without the proxy working .

**Solutions:**

1. **Install from system packages** (bypasses pip's network layer):
   ```bash
   sudo yum install python3-pysocks
   ```

2. **Temporarily clear proxy variables**:
   ```bash
   unset ALL_PROXY all_proxy HTTP_PROXY http_proxy HTTPS_PROXY https_proxy
   python3.11 -m pip install PySocks
   ```

3. **Force direct connection for one command**:
   ```bash
   python3.11 -m pip install PySocks --proxy=""
   ```

### Future pip Improvements

The pip team has recognized this issue. Starting with pip 26.2, a new `--no-proxy-env` flag will allow users to ignore environment-based proxy configurations entirely, and pip will gracefully fall back to direct connection when PySocks is missing .

## Why PySocks Matters in Enterprise Environments

In corporate networks with restricted internet access, PySocks serves as a critical bridge. It enables :

- Package installation through proxy servers
- Git operations via SOCKS proxies
- API calls to external services
- Any Python application requiring proxy support

The "chicken-and-egg" problem—where you need PySocks to use a proxy but need a proxy to install PySocks—makes the native RPM installation method particularly valuable for initial setup .

## Summary

| Task | Command/Method |
|------|----------------|
| Install via yum | `sudo yum install python3-pysocks` |
| Install via pip | `pip install PySocks` |
| Verify installation | `python3 -c "import socks; print(socks.__version__)"` |
| Basic usage | `socks.set_default_proxy(socks.SOCKS5, host, port)` |
| Configure pip | Add `proxy = socks5h://host:port` to pip.conf |

PySocks is essential for Python development in proxied environments. Whether you're installing packages, making API calls, or building network applications, understanding how to properly configure and use PySocks will save you from frustrating network-related errors.

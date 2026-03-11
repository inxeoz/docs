# Complete Guide: Setting up `iwctl` / iwd Networking on Linux (Arch-style)

This article explains **how to properly set up Wi-Fi using `iwctl` with the Intel wireless daemon**, configure networking, fix DNS issues, and ensure commands like:

```bash
sudo pacman -Syu
```

work correctly.

This guide assumes a **minimal Linux installation** (such as Arch Linux) where no graphical network manager is installed.

---

# 1. What is iwd and iwctl?

**iwd** is a modern wireless networking daemon developed by Intel. It manages Wi-Fi connections on Linux systems.

`iwctl` is the **interactive command-line client** used to control iwd.

It replaces older tools like:

* **wpa_supplicant**
* **dhcpcd** (in some setups)

Benefits of iwd:

* faster connection times
* simpler configuration
* built-in DHCP and DNS support
* fewer background services

---

# 2. Installing iwd

Most minimal Linux systems already include it.
If not, install it:

```bash
sudo pacman -S iwd
```

---

# 3. Enable the iwd Service

Start and enable the service:

```bash
sudo systemctl enable iwd
sudo systemctl start iwd
```

Check status:

```bash
systemctl status iwd
```

You should see:

```
Active: active (running)
```

---

# 4. Connecting to Wi-Fi with `iwctl`

Launch the interactive client:

```bash
iwctl
```

Prompt appears:

```
[iwd]#
```

---

## Step 1 — List wireless devices

```bash
device list
```

Example output:

```
Name   Address              Powered   Mode
wlan0  XX:XX:XX:XX:XX:XX    on        station
```

Your interface might also be named:

```
wlp2s0
```

---

## Step 2 — Scan networks

```bash
station wlan0 scan
```

Then display networks:

```bash
station wlan0 get-networks
```

Example:

```
Network name       Security    Signal
HomeWiFi           psk         ****
Office             psk         ***
CafeFree           open        **
```

---

## Step 3 — Connect to a network

```bash
station wlan0 connect "HomeWiFi"
```

Enter the password when prompted.

---

## Step 4 — Verify connection

```bash
station wlan0 show
```

Example output:

```
State: connected
Network: HomeWiFi
```

Exit iwctl:

```bash
exit
```

---

# 5. Enabling Automatic Network Configuration

For minimal systems, iwd can handle:

* DHCP
* IP assignment
* DNS

Edit the configuration file:

```bash
sudo nano /etc/iwd/main.conf
```

Add:

```ini
[General]
EnableNetworkConfiguration=true
```

Restart iwd:

```bash
sudo systemctl restart iwd
```

This allows iwd to **automatically configure networking after connecting to Wi-Fi**.

---

# 6. Fixing DNS Issues (Important)

Sometimes you can ping an IP:

```bash
ping 1.1.1.1
```

but domains fail:

```
ping google.com
```

This means **DNS is not configured**.

---

## Method 1 — Manual DNS (simple)

Edit:

```bash
sudo nano /etc/resolv.conf
```

Add:

```
nameserver 1.1.1.1
nameserver 8.8.8.8
```

Test:

```bash
ping google.com
```

---

## Method 2 — Automatic DNS with iwd

If this file exists:

```
/etc/iwd/main.conf
```

and contains:

```ini
[General]
EnableNetworkConfiguration=true
```

iwd will automatically configure DNS.

---

# 7. Ensure Wi-Fi is Not Blocked

Check wireless blocking:

```bash
rfkill list
```

If blocked:

```bash
sudo rfkill unblock wifi
```

---

# 8. Testing Internet Connectivity

First test raw connectivity:

```bash
ping -c 3 1.1.1.1
```

Then test DNS:

```bash
ping -c 3 google.com
```

Both should succeed.

---

# 9. Updating the System

Once networking works, update packages:

```bash
sudo pacman -Syu
```

This command:

* refreshes repositories
* upgrades installed packages

Example output:

```
:: Synchronizing package databases...
 core is up to date
 extra is up to date
 community is up to date
```

---

# 10. Automatic Wi-Fi Connection on Boot

Once you connect successfully, iwd **stores the network profile automatically**.

Profiles are saved in:

```
/var/lib/iwd/
```

Example:

```
HomeWiFi.psk
```

On next boot, iwd reconnects automatically.

---

# 11. Useful `iwctl` Commands

| Command                    | Description            |
| -------------------------- | ---------------------- |
| device list                | show Wi-Fi devices     |
| station wlan0 scan         | scan networks          |
| station wlan0 get-networks | list networks          |
| station wlan0 connect SSID | connect                |
| station wlan0 disconnect   | disconnect             |
| station wlan0 show         | show connection status |
| known-networks list        | saved networks         |

---

# 12. Common Problems and Fixes

## Problem: “Waiting for iwd to start”

Start service:

```bash
sudo systemctl start iwd
```

---

## Problem: `wlan0 disconnected`

Connect using:

```bash
station wlan0 connect NETWORK
```

---

## Problem: Pacman cannot resolve mirrors

Fix DNS:

```
/etc/resolv.conf
```

Add:

```
nameserver 1.1.1.1
```

---

# 13. Minimal Networking Setup (Recommended)

For a clean minimal system:

Installed services:

```
iwd
```

Configuration:

```
/etc/iwd/main.conf
```

```
[General]
EnableNetworkConfiguration=true
```

That's all.

No need for:

* NetworkManager
* dhcpcd
* systemd-networkd

---

# 14. Final Verification

Run these commands:

```bash
iwctl
station wlan0 show
```

Then:

```bash
ping google.com
```

Finally:

```bash
sudo pacman -Syu
```

If everything works, your networking is correctly configured.



# How to Set Up Automatic Wi-Fi Connection & Disconnection Alerts on Arch Linux (Hyprland / Wayland)

If you use a lightweight Wayland setup like **Hyprland** with **`iwd`** and **`systemd-networkd`** (common in minimal Arch setups like Omarchy), you might have noticed that NetworkManager desktop tools like `nm-applet` or `nmcli` aren't installed by default.

Standard event loops often cause two main annoyances:

1. **Spamming notifications** every time an interface refreshes its IP/IPv6 flags.
2. **Triggering alerts on manual disconnects** when you intentionally turned off Wi-Fi yourself.

Here is a guide to building a zero-polling, event-driven user daemon that handles **only automatic Wi-Fi drops**, debounces state changes, sends clean popups via `notify-send`, and plays a soft audio chime using PipeWire.

---

## Architecture Overview

Instead of constantly running a `sleep` loop or pinging servers, this daemon leverages Linux kernel and DBus signals:

* **Kernel Netlink Events (`ip monitor`)**: Intercepts physical layer link carrier status (`LOWER_UP` vs `NO-CARRIER`).
* **DBus Interception (`gdbus monitor`)**: Monitors `net.connman.iwd` for explicit user disconnect calls (e.g., via `iwctl`).
* **State Deduplication**: Compares state transitions to ensure exactly **one** alert fires per event.
* **PipeWire Audio (`pw-play`)**: Triggers system chime samples with an inline volume limiter.

---

## Prerequisites

Ensure you have basic notification utilities, DBus tools, and system sound themes installed:

```bash
sudo pacman -S libnotify glib2 sound-theme-freedesktop pipewire-audio

```

---

## Step 1: Create the Monitoring Script

Create a script at `~/.local/bin/net-notify.sh`:

```bash
mkdir -p ~/.local/bin
nvim ~/.local/bin/net-notify.sh

```

Paste the following shell script:

```bash
#!/usr/bin/env bash

INTERFACE="wlan0"
USER_DISCONNECT=0
CURRENT_STATE="UNKNOWN"

# Sound file paths (Freedesktop system theme)
DISCONNECT_SOUND="/usr/share/sounds/freedesktop/stereo/network-connectivity-lost.oga"
CONNECT_SOUND="/usr/share/sounds/freedesktop/stereo/network-connectivity-established.oga"

# Helper function to play audio with volume capping (0.3 = 30% volume)
play_sound() {
    local sound_file="$1"
    local volume="0.3" 
    
    if [ -f "$sound_file" ]; then
        pw-play --volume="$volume" "$sound_file" >/dev/null 2>&1 &
    fi
}

# Clean up background DBus subprocess on script exit
trap 'pkill -P $$' EXIT

# 1. Intercept user-initiated disconnect calls to iwd
gdbus monitor --system --dest net.connman.iwd | while read -r line; do
    if echo "$line" | grep -q "net.connman.iwd.Station.Disconnect"; then
        USER_DISCONNECT=1
    fi
done &

# 2. Listen to kernel netlink carrier events
ip monitor link dev "$INTERFACE" | while read -r line; do

    # Parse state from kernel flags
    if echo "$line" | grep -q "NO-CARRIER\|state DOWN"; then
        NEW_STATE="DISCONNECTED"
    elif echo "$line" | grep -q "LOWER_UP"; then
        NEW_STATE="CONNECTED"
    else
        continue
    fi

    # Deduplicate: Trigger ONLY when state actually transitions
    if [ "$NEW_STATE" != "$CURRENT_STATE" ]; then

        if [ "$NEW_STATE" = "DISCONNECTED" ]; then
            if [ "$USER_DISCONNECT" -eq 1 ]; then
                # User initiated disconnect -> stay quiet & reset flag
                USER_DISCONNECT=0
            else
                # Automatic/unintended drop -> Alert user
                play_sound "$DISCONNECT_SOUND"
                notify-send -a "Network" -i network-wireless-disconnected "Disconnected" "Wi-Fi connection lost"
            fi
            CURRENT_STATE="DISCONNECTED"

        elif [ "$NEW_STATE" = "CONNECTED" ]; then
            USER_DISCONNECT=0
            play_sound "$CONNECT_SOUND"
            notify-send -a "Network" -i network-wireless-connected "Connected" "Wi-Fi connected"
            CURRENT_STATE="CONNECTED"
        fi

    fi

done

```

Make the script executable:

```bash
chmod +x ~/.local/bin/net-notify.sh

```

---

## Step 2: Configure Systemd User Service

Rather than running this as a raw process in `hyprland.conf`, managing it as a `systemd --user` service ensures automatic restart on crashes and clean lifecycle handling.

Create the service file:

```bash
mkdir -p ~/.config/systemd/user
nvim ~/.config/systemd/user/net-notify.service

```

Add the service unit configuration:

```ini
[Unit]
Description=Wi-Fi Connectivity Notification Daemon
After=graphical-session.target

[Service]
ExecStart=%h/.local/bin/net-notify.sh
Restart=always
RestartSec=3

[Install]
WantedBy=default.target

```

Reload systemd daemon configurations and enable the service:

```bash
systemctl --user daemon-reload
systemctl --user enable --now net-notify.service

```

---

## Step 3: Testing & Verification

1. **Check Service Status**:
```bash
systemctl --user status net-notify.service

```


You should see `bash`, `gdbus monitor`, and `ip monitor` running under the service control group.
2. **Test Intentional Disconnect (Silent)**:
```bash
iwctl station wlan0 disconnect

```


*Expected Outcome*: The link drops, but **no notification or sound** triggers because `gdbus` flagged the user request.
3. **Test Automatic Drop (Triggers Alert)**:
Disable your router or phone hotspot.
*Expected Outcome*: An immediate visual popup **"Disconnected: Wi-Fi connection lost"** appears alongside a soft audio chime played at 30% volume.

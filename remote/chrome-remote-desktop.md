Complete Guide to Chrome Remote Desktop

*Setup • Share your screen • Access another computer*

---

## 🌐 What is Chrome Remote Desktop?

Chrome Remote Desktop lets you control a computer from anywhere through a browser. It works across platforms—Linux, Windows, macOS, even mobile.

Think of it as:

> a secure bridge between two machines using your Google account.

---

# ⚙️ PART 1 — Setting up Chrome Remote Desktop (Host machine)

This is the machine you want to access remotely (your Arch Linux system).

---

## 🧱 Step 1: Install required packages (Linux / Arch)

```bash
sudo pacman -S xfce4 xfce4-goodies xorg-server-xvfb xorg-xauth xorg-xsetroot
```

👉 XFCE is used because it’s lightweight and stable for remote sessions.

---

## 🧾 Step 2: Configure session file

```bash
nano ~/.chrome-remote-desktop-session
```

Add:

```bash
export $(dbus-launch)
exec startxfce4
```

👉 This ensures:

* proper desktop session
* working DBus (fixes crashes, audio issues)

---

## 🔐 Step 3: Register your machine

Go to:

👉 [https://remotedesktop.google.com/headless/](https://remotedesktop.google.com/headless/)

Copy the command and run it:

```bash
DISPLAY= /opt/google/chrome-remote-desktop/start-host --code="..." ...
```

You will:

* set a **PIN**
* register the device to your Google account

---

## ⚙️ Step 4: Start the service

```bash
systemctl enable chrome-remote-desktop@$USER
systemctl start chrome-remote-desktop@$USER
```

Check status:

```bash
systemctl status chrome-remote-desktop@$USER
```

You want:

```
Active: active (running)
```

---

# 🔗 PART 2 — Access your computer (from Windows)

On the Windows machine:

### Option A: Browser (easiest)

Open:
👉 [https://remotedesktop.google.com/access](https://remotedesktop.google.com/access)

Steps:

1. Login with same Google account
2. Select your computer
3. Enter PIN

---

### Option B: Use a browser like:

* Google Chrome
* Microsoft Edge

👉 Best compatibility and performance.

---

## 🧠 What happens behind the scenes

* Linux runs a virtual display (`:20`)
* XFCE desktop starts
* Browser streams it securely

---

# 🧑‍🤝‍🧑 PART 3 — Share your screen with another user

You have **two methods**, depending on your goal.

---

## 🔐 Method 1: Temporary sharing (recommended)

Go to:
👉 [https://remotedesktop.google.com/support](https://remotedesktop.google.com/support)

### On your machine:

1. Click **“Share this screen”**
2. Generate a **one-time code**

### On Windows user:

1. Enter that code
2. Instantly connect

👉 No account sharing required.

---

## 👥 Method 2: Permanent access

If you trust the user:

* Share your Google account
  **or**
* Add their Google account to your machine

Then they:

* log in
* see your system
* connect anytime with PIN

---

## ⚠️ Important behavior

* Only **one session per host**
* All users see the **same desktop**
* It’s not multi-user like a server

---

# 🔄 PART 4 — Access another user’s screen

If *you* want to access someone else:

---

## Option A: They share code

1. Ask them to open:
   👉 [https://remotedesktop.google.com/support](https://remotedesktop.google.com/support)
2. They generate code
3. You enter it

👉 Instant access

---

## Option B: They enable remote access

They:

* install CRD
* set PIN

You:

* log into their account
* connect from Access page

---

# 🧪 Troubleshooting

---

## ❌ Infinite PIN loop

Cause:

* setup command running inside service

Fix:

* run setup manually in terminal

---

## 🖤 Black screen

Cause:

* no desktop environment

Fix:

```bash
exec startxfce4
```

---

## 🔇 No audio / DBus errors

Fix:

```bash
export $(dbus-launch)
```

---

## ❌ Service not running

Check:

```bash
journalctl -u chrome-remote-desktop@$USER -e
```

---

# 🚀 Advanced Tips

---

## ⚡ Reduce RAM usage

Switch XFCE → lightweight WM:

* Openbox
* i3

---

## 🔐 Security tips

* Use strong PIN
* Don’t share Google account casually
* Prefer temporary codes for strangers

---

## 🌍 Access from mobile

Install:

* Chrome Remote Desktop

---

# 🧠 Final Understanding

* Not a VM → it’s your real system
* Not multi-user → shared session
* Not local-only → works over internet

---

# 🏁 Summary

| Task          | How                                       |
| ------------- | ----------------------------------------- |
| Setup         | Install + session file + headless command |
| Access        | Use Access page + PIN                     |
| Share screen  | Support page + one-time code              |
| Access others | Enter their code                          |

---

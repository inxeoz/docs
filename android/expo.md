# Why `adb reverse tcp:8081 tcp:8081` Fixed My Expo Connection (And Why Everything Else Failed)

When developing with **React Native** using **Expo**, one of the most frustrating errors you can encounter is:

> **“Failed to download remote update”**

Even worse, you might also see:

> **“Failed to resolve the Android SDK path”**

At first glance, it feels like you need to install **Android SDK** or Android Studio.

But in many cases — especially when using a mobile hotspot — the real problem is networking.

This article explains:

* Why LAN mode failed
* Why tunnel mode failed
* Why pressing `a` triggered SDK errors
* And why `adb reverse` worked instantly

---

# How Expo Normally Connects to Your Phone

When you run:

```bash
expo start
```

Expo launches the **Metro Bundler** on your computer (usually on port 8081).

Your phone then downloads the JavaScript bundle from your computer.

The connection method depends on how you start Expo.

---

# 1️⃣ LAN Mode (Default) — Why It Failed

When Expo shows something like:

```
exp://10.155.153.121:8081
```

It means your phone is trying to connect to your computer over the local network:

```
Phone → WiFi / Hotspot → Computer
```

### The Problem with Mobile Hotspots

Mobile hotspots often:

* Isolate connected devices
* Block device-to-device communication
* Restrict internal IP routing

So your phone cannot reach:

```
10.155.153.121
```

That’s why Expo Go shows:

> Failed to download remote update

The app is working.
Metro is running.
But the phone cannot reach your computer.

---

# 2️⃣ Tunnel Mode — Why It Also Failed

Tunnel mode works differently:

```
Phone → Internet → Expo servers → Your computer
```

Expo uses ngrok to create a public tunnel to your local machine.

This avoids local network problems.

However, it can fail if:

* Your carrier blocks tunneling
* Ngrok cannot establish a connection
* Your network restricts outbound tunnels
* Hotspot traffic is filtered

That’s why you saw:

> ngrok tunnel took too long to connect

Tunnel mode depends on external servers and network permissions. If those are blocked, it won’t work.

---

# 3️⃣ Pressing `a` — Why It Triggered SDK Errors

When you press:

```
a
```

Expo tries to:

* Use the Android SDK
* Launch an emulator
* Or install a development build using SDK tools

If you don’t have Android Studio or the Android SDK installed, you’ll see:

```
Failed to resolve the Android SDK path
```

Important:

This error has **nothing to do with networking**.

It only appears because Expo tried to use local Android development tools.

If you're using Expo Go on a real device, you don’t need the SDK at all.

---

# 4️⃣ Why `adb reverse tcp:8081 tcp:8081` Worked

This command changes everything.

When you run:

```bash
adb reverse tcp:8081 tcp:8081
```

You tell your Android device:

> “Whenever you try to access port 8081, redirect it to my computer’s port 8081 through USB.”

Now the connection path becomes:

```
Phone → USB cable → Computer → Metro Bundler
```

No WiFi.
No hotspot.
No router.
No internet.
No tunnel.
No Android SDK.

It’s a direct wired bridge.

That’s why it worked instantly.

---

# What `adb reverse` Actually Does

* `tcp:8081` (first part) = port on the phone
* `tcp:8081` (second part) = port on your computer

It forwards traffic from the phone to your local machine through USB using ADB.

After running it, you can even manually enter:

```
exp://127.0.0.1:8081
```

And it works — because your phone now treats your computer as localhost.

---

# When to Use Each Method

| Situation                      | Best Method             |
| ------------------------------ | ----------------------- |
| Same home WiFi                 | LAN mode                |
| Corporate / restricted network | Tunnel mode             |
| Mobile hotspot                 | **adb reverse (USB)**   |
| No physical device             | Android Studio emulator |

---

# Why Many Developers Prefer USB Anyway

Even when WiFi works, many developers prefer USB + `adb reverse` because:

* It’s faster
* It’s more stable
* No router/firewall issues
* No dependency on external servers
* No random network debugging

It removes an entire class of problems.

---

# Final Takeaway

If you're using a mobile hotspot and Expo keeps failing:

You probably don’t need:

* Android Studio
* Android SDK
* Tunnel mode
* Router configuration

You just need:

```bash
adb reverse tcp:8081 tcp:8081
```

And then start Expo normally.

Sometimes the simplest path — a direct wired connection — is the most reliable one.

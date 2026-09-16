# Connect Linux and Android Using Cloudflare One

You can connect a **Linux laptop and Android phone directly through Cloudflare One** without setting up a VPN server, port forwarding, or a Mesh node.

## What you need

* A Cloudflare Zero Trust account
* Two email accounts
* Both emails allowed by your Cloudflare Access/Zero Trust policy
* Cloudflare One Client on Linux
* Cloudflare One Agent on Android

---

## 1. Allow both email accounts

In Cloudflare Zero Trust, go to:

**Team & Resources → Devices → Device profiles**

Open your **Onboarding Device profile**.

Make sure both email addresses are allowed for device enrollment.

For example:

```text
user1@example.com
user2@example.com
```

Also make sure your **Allow policy** permits both users.

---

## 2. Connect the Linux laptop

Install the Cloudflare One Client on Linux and enroll it using the **first email**.

After authentication:

```text
Cloudflare One Client
        ↓
Connected
```

Cloudflare will create a **device record** for the laptop.

Open the device record and note its assigned:

```text
IPv4: 100.x.x.x
IPv6: ...
```

For example:

```text
Linux
IPv4: 100.96.0.2
```

---

## 3. Connect the Android phone

Install **Cloudflare One Agent** on Android.

Enter your Cloudflare team name and authenticate using the **second email**.

Once connected, Cloudflare creates another device record.

For example:

```text
Android
IPv4: 100.96.0.3
```

---

## 4. Connect to the other device

Now both devices are enrolled:

```text
                 Cloudflare
                /          \
               /            \
          Linux              Android
       100.96.0.2          100.96.0.3
```

From Android, you can SSH to Linux:

```bash
ssh username@100.96.0.2
```

Or from Linux, connect to a service running on Android using its Cloudflare-assigned IP and port.

---

## 5. That's it

You don't need to configure:

* ❌ Port forwarding
* ❌ Public IP
* ❌ VPN server
* ❌ Router configuration
* ❌ `cloudflared` tunnel
* ❌ Mesh node
* ❌ Wi-Fi subnet routing

The important part is simply:

```text
1. Allow both emails
2. Enroll Linux with email #1
3. Enroll Android with email #2
4. Both devices receive Cloudflare IP addresses
5. Connect using those IP addresses
```

### Mental model

Think of Cloudflare as creating a private network between your **enrolled devices**:

```text
Laptop ───── Cloudflare ───── Phone
  IP1                         IP2
```

Your physical networks can be completely different. The laptop could be on Wi-Fi while the phone is on mobile data.

**The device's local IP doesn't matter. Use the Cloudflare-assigned device IP.**

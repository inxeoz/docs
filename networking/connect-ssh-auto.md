# How to Connect to a Server Using SSH Keys and an SSH Config File

If you're still typing passwords every time you SSH into a server, you're doing it the hard way. SSH keys plus a well-written `~/.ssh/config` file turn a multi-step, password-prompting chore into a single short command — and they're the foundation for everything from port forwarding to automated tunnels.

This guide walks through the full setup: generating a key pair, installing the public key on the server, and writing a config file that eliminates passwords, quoting headaches, and stale connections.

---

## Why SSH Keys Beat Passwords

Password authentication has three problems:

1. **It's slow.** Every connection requires typing (or pasting) a password.
2. **It's weak.** Passwords can be brute-forced, phished, or reused across services.
3. **It's script-hostile.** Any automation — `scp`, `rsync`, `autossh`, reverse tunnels — stalls on an interactive password prompt.

SSH keys solve all three. You generate a cryptographic key pair once, install the public half on the server, and keep the private half on your client. After that, authentication is automatic and far more resistant to attack.

---

## Step 1: Generate an SSH Key Pair

On your **local machine**:

```bash
ssh-keygen -t ed25519 -C "you@example.com"
```

Breaking that down:

- **`-t ed25519`** — Uses the Ed25519 algorithm. It's faster, shorter, and more secure than the older RSA. If you're on a very old system that lacks Ed25519, fall back to `-t rsa -b 4096`.
- **`-C "you@example.com"`** — A comment, usually your email, embedded in the key for identification. Purely cosmetic.

You'll be prompted for:

- **A file location.** Press Enter to accept the default `~/.ssh/id_ed25519`, or give it a custom name like `~/.ssh/inxeoz_server_key` if you manage multiple servers.
- **A passphrase.** Optional but recommended. It encrypts the private key at rest, so a stolen key file is useless without it. If you use a passphrase, pair it with `ssh-agent` (covered later) so you don't type it every time.

This produces two files:

| File | Purpose | Share it? |
|---|---|---|
| `id_ed25519` | Private key | **Never** |
| `id_ed25519.pub` | Public key | Yes — this goes on servers |

---

## Step 2: Install the Public Key on the Server

The simplest method uses the `ssh-copy-id` utility:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server.example.com
```

You'll be asked for the server password **one last time**. The command creates `~/.ssh` on the server if needed and appends your public key to `~/.ssh/authorized_keys`.

### Manual alternative

If `ssh-copy-id` isn't available:

```bash
# 1. Print your public key
cat ~/.ssh/id_ed25519.pub

# 2. Copy the entire output, then log in with your password
ssh user@server.example.com

# 3. On the server, paste the key
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "PASTE_YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Permissions matter

SSH refuses to use keys with loose permissions. On your **local** machine:

```bash
chmod 600 ~/.ssh/id_ed25519
```

On the **server**:

- `~/.ssh` → `700`
- `~/.ssh/authorized_keys` → `600`

Get these wrong and SSH will silently ignore your key, leaving you confused at a password prompt.

### Test it

```bash
ssh -i ~/.ssh/id_ed25519 user@server.example.com
```

If you land in a shell without a password prompt, key auth is working. (You may see a passphrase prompt if you set one — that's your key's passphrase, not the server's password.)

---

## Step 3: Write an SSH Config File

Logging in with `ssh -i ~/.ssh/id_ed25519 user@server.example.com` every time works, but it's verbose. The `~/.ssh/config` file lets you define a short alias with all your preferences baked in.

Create or edit `~/.ssh/config` on your local machine:

```ini
Host myserver
    HostName server.example.com
    User inxeoz
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 3
    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 10m
```

Now you can connect with just:

```bash
ssh myserver
```

### What each option does

**`Host myserver`** — The alias you'll type. Any name works.

**`HostName server.example.com`** — The real address (hostname or IP).

**`User inxeoz`** — The remote username. Skips typing `user@`.

**`Port 22`** — The SSH port. Only needed if the server uses a non-default port.

**`IdentityFile ~/.ssh/id_ed25519`** — Which private key to use. Without this, SSH tries every key it can find, which can be slow and can trigger lockouts.

**`IdentitiesOnly yes`** — Offer *only* the key above. Critical if you have many keys or an `ssh-agent` running: servers limit auth attempts (often 6), and offering the wrong keys first can lock you out before the right one is tried.

**`ServerAliveInterval 30`** — Send a keepalive every 30 seconds. Detects dead connections (network drops, sleeping laptops) that would otherwise hang silently. Also stops NAT/firewall devices from timing out your idle session.

**`ServerAliveCountMax 3`** — Give up after 3 unanswered keepalives. Combined with the interval above, the client detects a dead connection in roughly 90 seconds.

**`ControlMaster auto`** — Enable connection multiplexing. The first connection becomes a "master"; subsequent connections to the same host reuse it — no new TCP handshake, no re-authentication.

**`ControlPath ~/.ssh/cm-%r@%h:%p`** — Where the master connection's Unix socket lives. The tokens expand to `user@host:port`, so each server gets its own socket. Keep this path short — Unix sockets have a ~108-character limit.

**`ControlPersist 10m`** — How long the master connection stays alive after the last session closes. `10m` means you can disconnect and reconnect within ten minutes with zero re-auth. Use `yes` to keep it forever, `0` to close immediately.

---

## Step 4: The Payoff — Passwordless Automation

With keys installed and the config in place, multi-step workflows collapse into single commands. For example, a local SOCKS proxy plus a reverse tunnel to a remote server:

```bash
# Terminal 1 — local SOCKS proxy on port 9050
ssh -D 9050 -fN localhost

# Terminal 2 — reverse tunnel: remote's 19052 → local's 9050
ssh -N -R 19052:localhost:9050 myserver
```

On the remote server:

```bash
export ALL_PROXY="socks5h://127.0.0.1:19052"
curl -m 8 https://example.com
```

Because ControlMaster is active, the second `ssh` call reuses the master connection — no password prompt, no key re-exchange. This is what makes tools like `autossh` actually viable: they can reconnect unattended only when authentication is automatic.

---

## Common Pitfalls

**Permission errors.** `chmod 600` on the private key, `700` on `~/.ssh`, `600` on `authorized_keys`. SSH is strict.

**"Too many authentication failures."** Usually caused by an `ssh-agent` offering several keys before the right one. Fix with `IdentitiesOnly yes`.

**"ControlPath too long."** The socket path exceeds ~108 characters. Shorten it, e.g. `~/.ssh/cm-%r@%h:%p`.

**Stale port listeners on the server.** If a reverse tunnel (`-R`) dies uncleanly, the server may keep the port bound. This happens when `ClientAliveInterval` is disabled in the server's `sshd_config` — the server never notices the client is gone. Workaround: use a fresh port each time, or clean up manually with `sudo fuser -k PORT/tcp`.

**Cosmetic warnings.** Messages like `connection is not using a post-quantum key exchange algorithm` simply mean the server runs an older OpenSSH. They don't affect functionality.

---

## Optional: Using ssh-agent

If you set a passphrase on your key, `ssh-agent` caches it for the session so you type it once:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

Most desktop environments start the agent automatically. On servers, `AllowAgentForwarding` in `sshd_config` controls whether the agent can be forwarded onward — leave it off unless you specifically need it.

---

## Summary

1. **Generate** a key pair with `ssh-keygen -t ed25519`.
2. **Install** the public key on the server with `ssh-copy-id`.
3. **Configure** `~/.ssh/config` with an alias, `IdentityFile`, `IdentitiesOnly`, keepalives, and ControlMaster.
4. **Connect** with a single short command and enjoy passwordless, multiplexed sessions.

Once this is in place, the friction disappears. Tunnels, scripts, and automation all just work — and your server is more secure than it was with password auth.

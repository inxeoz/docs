
# 🐳 Running phpMyAdmin with Docker (and fixing every common error on Linux)

Running phpMyAdmin in Docker sounds trivial—until Linux networking, MySQL auth, and firewalls get involved. This guide walks from zero → working setup, including the exact errors you hit.

---

# ⚡ 1. The goal

You already have:

* Local MariaDB running on your system
* Want phpMyAdmin via Docker
* No full LAMP stack setup

---

# 🚀 2. Basic (but incomplete) command

Most guides say:

```bash
docker run -d -p 8080:80 phpmyadmin
```

This runs—but **won’t connect to your database**.

---

# ❌ 3. Common errors you’ll hit

### 1. ❌ `host.docker.internal` not working

```
php_network_getaddresses: getaddrinfo failed
```

👉 Linux doesn’t support it by default.

---

### 2. ❌ Endless loading after login

* No error
* Just spins forever

👉 This is **network timeout to MySQL**

---

### 3. ❌ Using wrong DB host

```
getaddrinfo for fm_global-db failed
```

👉 Happens if you accidentally point to another container

---

### 4. ❌ Connection hangs (no response)

Even `nc` test hangs:

```bash
nc -zv 10.222.0.1 3306
```

👉 This means **firewall is blocking Docker → host**

---

# 🧠 4. Key concept (this unlocks everything)

On Linux:

| Thing            | Meaning                 |
| ---------------- | ----------------------- |
| Docker container | separate network        |
| Host machine     | reachable via bridge IP |
| Docker bridge    | usually `docker0`       |

👉 Your host is accessible as something like:

```
10.222.0.1
```

---

# 🔍 5. Find your host IP from Docker

```bash
ip addr show docker0
```

Example:

```text
inet 10.222.0.1/24
```

👉 That’s your **real target for MySQL**

---

# 🔓 6. Fix MariaDB (critical)

Edit config:

```bash
sudo nano /etc/my.cnf
```

Change:

```ini
bind-address = 0.0.0.0
```

Restart:

```bash
sudo systemctl restart mariadb
```

---

## 👤 Allow remote user

```bash
mariadb -u root -p
```

```sql
CREATE USER 'admin'@'%' IDENTIFIED BY 'admin123';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';
FLUSH PRIVILEGES;
```

---

# 🔥 7. Fix firewall (THE hidden issue)

Allow Docker subnet:

```bash
sudo iptables -I INPUT -p tcp -s 10.222.0.0/24 --dport 3306 -j ACCEPT
```

---

## 🧪 Test connection (important)

Inside container:

```bash
docker exec -it phpmyadmin bash
apt install -y netcat-openbsd
nc -zv 10.222.0.1 3306
```

✅ You want:

```
succeeded
```

---

# 🚀 8. Final working command

```bash
docker run -d \
  --name phpmyadmin \
  -p 8080:80 \
  -e PMA_HOST=10.222.0.1 \
  --restart unless-stopped \
  -e PMA_USER=admin \
  -e PMA_PASSWORD=admin123 \
  phpmyadmin
```

---

# 🌍 9. Access phpMyAdmin

```
http://localhost:8080
```

👉 You should be logged in instantly.

---

# 🧠 10. Why it failed earlier

| Problem                    | Cause                         |
| -------------------------- | ----------------------------- |
| Infinite loading           | DB not reachable              |
| host.docker.internal error | not supported on Linux        |
| Wrong container DB         | confusion with other services |
| Connection hang            | firewall blocking             |
| Login loop                 | MySQL auth mismatch           |

---

# ⚠️ 11. Security notes (don’t skip)

* Don’t expose port 3306 publicly
* Prefer non-root user (`admin`)
* Restrict firewall to Docker subnet only

---

# 🧩 12. Optional: cleaner setup (docker-compose)

```yaml
version: '3'
services:
  phpmyadmin:
    image: phpmyadmin
    ports:
      - 8080:80
    environment:
      PMA_HOST: 10.222.0.1
      PMA_USER: admin
      PMA_PASSWORD: admin123
```

Run:

```bash
docker compose up -d
```

---

# 🎯 Final takeaway

On Linux, the real trick is:

👉 **Container → Host = Docker bridge IP (NOT localhost)**
👉 **Firewall must allow that path**

Everything else is noise.


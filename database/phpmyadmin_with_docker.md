

# 🐳 Running phpMyAdmin with Docker on Linux (Fast + Correct Setup)

Running **phpMyAdmin** with Docker on Linux isn’t hard—but most guides miss key details around networking *and performance*. This version gets you a **working + fast setup**.

---

# ⚡ 1. The goal

You have:

* Local **MariaDB** running on your system
* Want phpMyAdmin via **Docker**
* No full LAMP stack

---

# 🚀 2. The correct minimal command (modern)

```bash
docker run -d \
  --name phpmyadmin \
  -p 8080:80 \
  --add-host=host.docker.internal:host-gateway \
  -e PMA_HOST=host.docker.internal \
  phpmyadmin
```

👉 This is the **correct replacement** for using raw bridge IPs like `10.x.x.x`.

---

# 🧠 3. Key concept (this changed everything)

Old approach:

```
Container → docker0 IP → host → DB
```

New (correct) approach:

```
Container → host.docker.internal → DB
```

👉 Cleaner, more stable, less latency.

---

# ❌ 4. Common errors (and real causes)

### 1. `host.docker.internal` not working

```
getaddrinfo failed
```

👉 Fix: add

```bash
--add-host=host.docker.internal:host-gateway
```

---

### 2. Infinite loading / slow UI

👉 Not networking anymore—it’s usually:

* DNS lookup delay in MariaDB
* low buffer pool
* PHP overhead

---

### 3. Wrong DB host

```
getaddrinfo failed
```

👉 Happens when pointing to unrelated containers (e.g., frappe DB)

---

### 4. Connection hang

👉 Usually firewall—but less common if using `host.docker.internal`

---

# 🔓 5. MariaDB must be reachable

Edit config:

```bash
sudo nano /etc/my.cnf
```

Ensure:

```ini
[mariadb]
bind-address = 0.0.0.0
```

Restart:

```bash
sudo systemctl restart mariadb
```

---

## 👤 Allow access

```sql
CREATE USER 'admin'@'%' IDENTIFIED BY 'admin123';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';
FLUSH PRIVILEGES;
```

---

# ⚡ 6. **Critical performance fix (MOST IMPORTANT)**

Without this, phpMyAdmin feels slow even if everything “works”.

Edit:

```bash
sudo nano /etc/my.cnf
```

Add:

```ini
[mysqld]
skip-name-resolve
innodb_buffer_pool_size=512M
innodb_log_file_size=128M
```

Restart:

```bash
sudo systemctl restart mariadb
```

---

## 🧠 Why this matters

| Problem      | Effect               |
| ------------ | -------------------- |
| DNS lookup   | delay on every query |
| small buffer | disk reads (slow)    |

👉 These cause the “laggy clicks” feeling.

---

# 🔥 7. Firewall (only if needed)

If connection fails:

```bash
sudo ufw allow from 172.17.0.0/16 to any port 3306
```

👉 Docker default subnet

---

# 🧪 8. Test connection

```bash
docker exec -it phpmyadmin bash
apt update && apt install -y netcat-openbsd
nc -zv host.docker.internal 3306
```

✅ Expect:

```
succeeded
```

---

# 🌍 9. Access

```
http://localhost:8080
```

---

# ⚡ 10. Make phpMyAdmin faster (optional but recommended)

```bash
docker run -d \
  --name phpmyadmin \
  -p 8080:80 \
  --add-host=host.docker.internal:host-gateway \
  -e PMA_HOST=host.docker.internal \
  -e PHP_OPCACHE_ENABLE=1 \
  phpmyadmin
```
use ``--restart always`` for automatic start at boot
👉 Enables PHP caching → faster UI

---

# 🧠 11. Why it was slow before

| Issue        | Cause                                     |
| ------------ | ----------------------------------------- |
| Laggy clicks | DNS lookups (`skip-name-resolve` missing) |
| Slow queries | tiny buffer pool                          |
| Random delay | indirect IP routing                       |
| UI sluggish  | PHP recompiling                           |

---

# ⚠️ 12. Security notes

* Don’t expose port 3306 publicly
* Use non-root user
* Restrict firewall to Docker subnet

---

# 🧩 13. Optional docker-compose

```yaml
version: '3'
services:
  phpmyadmin:
    image: phpmyadmin
    ports:
      - 8080:80
    extra_hosts:
      - "host.docker.internal:host-gateway"
    environment:
      PMA_HOST: host.docker.internal
      PMA_USER: admin
      PMA_PASSWORD: admin123
```

---

# 🎯 Final takeaway

On Linux, the real solution is:

👉 Use `host.docker.internal` (not raw IPs)
👉 Disable DNS lookups in MariaDB
👉 Increase buffer pool

Everything else is secondary.

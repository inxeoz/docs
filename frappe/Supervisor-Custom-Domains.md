# Frappe Production Setup: Supervisor, Process Management, Custom Domains, and Domain Sync

This guide documents a practical way to run a Frappe/ERPNext bench in production using **Supervisor**, and configure it so that sites are accessed through a real domain instead of manually specifying a `Host` header.

It is based on the setup we just fixed on your server, including the important `.ini` issue with Supervisor on RHEL/AlmaLinux-style systems.

Frappe's production documentation describes Supervisor and Nginx as the two main components for a traditional bare-metal production setup: Supervisor keeps Frappe processes alive, while Nginx handles HTTP/static-file serving and proxies requests to Frappe. ([Frappe Docs][1])

---

## 1. Architecture

A typical production deployment looks like this:

```text
                    Internet
                       │
                       │
              shipra.mp.gov.in
                       │
                       ▼
                  DNS record
                       │
                       ▼
                ┌─────────────┐
                │    Nginx    │
                │   :80/:443  │
                └──────┬──────┘
                       │
                       │ proxy
                       ▼
                ┌─────────────┐
                │   Frappe    │
                │    :8000    │
                └──────┬──────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
       Redis       Socket.IO     Workers
```

Supervisor sits alongside this:

```text
                 supervisord
                     │
       ┌─────────────┼──────────────┐
       │             │              │
       ▼             ▼              ▼
     Redis          Web          Workers
       │             │              │
       │             ├─ Frappe      ├─ scheduler
       │             └─ Socket.IO   ├─ short workers
       │                            └─ long workers
       ▼
   queues/cache
```

The important idea is:

> **Nginx handles incoming HTTP traffic. Supervisor keeps the Frappe processes running. Frappe handles site/domain routing. DNS points the domain to the server.**

---

# 2. Understand the Bench directory

Assume your bench is:

```text
/home/inxeoz/pro
```

A normal Frappe bench contains:

```text
pro/
├── apps/
├── config/
├── env/
├── logs/
├── sites/
├── Procfile
└── ...
```

Frappe's documentation describes `config/` as the location for generated Redis, Nginx and Supervisor configuration, while `sites/` contains the individual Frappe sites and common configuration. ([Frappe Docs][2])

The important directories are:

```text
config/
    ├── redis_cache.conf
    ├── redis_queue.conf
    ├── nginx.conf
    └── supervisor.conf

sites/
    ├── common_site_config.json
    └── your-site/
```

---

# 3. What is Supervisor?

Supervisor is a process manager.

Instead of manually doing:

```bash
bench start
```

and keeping a terminal open, Supervisor starts the individual processes and automatically restarts them if they terminate.

For example:

```text
Frappe web
Redis
Socket.IO
Scheduler
Workers
```

Frappe specifically recommends Supervisor for keeping the processes that power a production installation running. ([Frappe Docs][1])

A healthy installation can be checked with:

```bash
sudo supervisorctl status
```

Frappe's production documentation uses this same command to verify that Redis, web, Socket.IO and worker processes are running. ([Frappe Docs][3])

---

# 4. Generate Frappe's Supervisor configuration

From your bench:

```bash
cd /home/inxeoz/pro
```

Generate the configuration:

```bash
bench setup supervisor
```

This generates:

```text
config/supervisor.conf
```

Frappe documents `bench setup supervisor` as the command for generating the Supervisor configuration. ([Frappe Docs][1])

Inspect it:

```bash
cat config/supervisor.conf
```

You will typically see sections such as:

```ini
[program:pro-redis-cache]

[program:pro-redis-queue]

[program:pro-frappe-web]

[program:pro-node-socketio]

[program:pro-frappe-schedule]

[program:pro-frappe-short-worker]

[program:pro-frappe-long-worker]
```

and groups such as:

```ini
[group:pro-web]

[group:pro-workers]

[group:pro-redis]
```

Groups are useful because Supervisor lets you operate several related programs together. Supervisor's configuration supports `[group:x]` sections specifically for grouping programs. ([docs.supervisord.org][4])

---

# 5. The important RHEL/AlmaLinux `.ini` issue

This was the main problem in our setup.

We initially had:

```text
/etc/supervisord.d/frappe.conf
```

pointing to:

```text
/home/inxeoz/pro/config/supervisor.conf
```

But Supervisor was configured with:

```ini
[include]
files = supervisord.d/*.ini
```

Therefore:

```text
frappe.conf
```

did **not** match:

```text
*.ini
```

and Supervisor simply ignored it.

Supervisor's `[include]` section uses file globs, so only files matching the configured pattern are included. ([docs.supervisord.org][4])

Check your system:

```bash
sudo grep -n -A10 -B2 '\[include\]' /etc/supervisord.conf
```

If you see:

```ini
[include]
files = supervisord.d/*.ini
```

then your Frappe configuration must have an `.ini` extension.

---

# 6. Link the Frappe Supervisor configuration

Create the link:

```bash
sudo ln -s /home/inxeoz/pro/config/supervisor.conf \
    /etc/supervisord.d/frappe.ini
```

Verify:

```bash
sudo ls -l /etc/supervisord.d/frappe.ini
```

You should see:

```text
frappe.ini -> /home/inxeoz/pro/config/supervisor.conf
```

If an old `.conf` symlink exists:

```bash
sudo rm /etc/supervisord.d/frappe.conf
```

then create the `.ini` link.

Frappe's production documentation similarly recommends linking the generated `config/supervisor.conf` into Supervisor's configuration directory; the exact extension depends on the distribution's Supervisor include configuration. ([Frappe Docs][1])

---

# 7. Reload Supervisor configuration

After changing the configuration:

```bash
sudo supervisorctl reread
```

A successful result looks like:

```text
pro-redis: available
pro-web: available
pro-workers: available
```

Then:

```bash
sudo supervisorctl update
```

You should see:

```text
pro-redis: added process group
pro-web: added process group
pro-workers: added process group
```

Finally:

```bash
sudo supervisorctl status
```

For our setup, the result looked approximately like:

```text
pro-redis:pro-redis-cache                 RUNNING
pro-redis:pro-redis-queue                 RUNNING

pro-web:pro-frappe-web                    RUNNING
pro-web:pro-node-socketio                 RUNNING

pro-workers:pro-frappe-schedule           RUNNING

pro-workers:pro-frappe-short-worker-0     RUNNING
pro-workers:pro-frappe-short-worker-1     RUNNING
pro-workers:pro-frappe-short-worker-2     RUNNING
pro-workers:pro-frappe-short-worker-3     RUNNING

pro-workers:pro-frappe-long-worker-0      RUNNING
pro-workers:pro-frappe-long-worker-1      RUNNING
pro-workers:pro-frappe-long-worker-2      RUNNING
pro-workers:pro-frappe-long-worker-3      RUNNING
```

This is a good health check.

---

# 8. Common Supervisor commands

### Show everything

```bash
sudo supervisorctl status
```

### Reload configuration

```bash
sudo supervisorctl reread
```

### Apply configuration changes

```bash
sudo supervisorctl update
```

### Restart everything

```bash
sudo supervisorctl restart all
```

### Stop everything

```bash
sudo supervisorctl stop all
```

### Start everything

```bash
sudo supervisorctl start all
```

### Restart one group

```bash
sudo supervisorctl restart pro-web:*
```

or:

```bash
sudo supervisorctl restart pro-workers:*
```

This is often better than restarting everything when you only changed application code.

---

# 9. Build frontend assets

When you change JavaScript, CSS or frontend assets:

```bash
bench build
```

Then:

```bash
sudo supervisorctl restart all
```

Or:

```bash
bench build && sudo supervisorctl restart all
```

Frappe's `bench update` can also perform the broader update workflow, including pulling applications, patches, asset builds and restarting the bench. ([Frappe Docs][3])

For a normal application-code change:

```bash
sudo supervisorctl restart all
```

is usually enough.

---

# 10. Why `curl 127.0.0.1:8000` returned 404

This was another important part of the debugging process.

Running:

```bash
curl http://127.0.0.1:8000
```

sent:

```http
Host: 127.0.0.1
```

Frappe interpreted that hostname as the site name.

If your site is:

```text
localhost
```

then:

```bash
curl http://127.0.0.1:8000
```

can produce:

```text
404 Not Found

127.0.0.1 does not exist.
```

But:

```bash
curl -H "Host: localhost" http://127.0.0.1:8000
```

works because Frappe receives:

```http
Host: localhost
```

and therefore selects:

```text
sites/localhost
```

This demonstrates an important Frappe concept:

> **The HTTP hostname can be used to select the Frappe site.**

That is exactly what we want for a real domain.

---

# 11. Don't use `Host:` manually in production

You should **not** need to run:

```bash
curl -H "Host: localhost" ...
```

every time.

Instead, configure:

```text
shipra.mp.gov.in
```

as the site's domain.

Then the normal request:

```text
https://shipra.mp.gov.in
```

contains:

```http
Host: shipra.mp.gov.in
```

automatically.

Frappe supports DNS-based multitenancy where the hostname determines which site is selected. ([Frappe Docs][5])

---

# 12. Option 1 — Make the Frappe site itself use the domain

If this is a new/test installation and the current site is:

```text
localhost
```

you can create the site with its actual domain:

```bash
bench new-site shipra.mp.gov.in
```

Then install your apps:

```bash
bench --site shipra.mp.gov.in install-app your_app
```

Set it as the active/default site:

```bash
bench use shipra.mp.gov.in
```

And, if appropriate:

```bash
bench set-config -g default_site shipra.mp.gov.in
```

The Frappe production documentation shows the normal pattern of creating sites with their intended hostname. ([Frappe Docs][3])

### Important

If your existing `localhost` site already contains data, **don't simply rename its directory without considering the site's database and configuration**.

For an existing production site, the safer approach is generally to add the domain rather than destroy/recreate the site.

---

# 13. Option 2 — Add a custom domain to an existing site

This is usually the better approach for an existing site.

Frappe provides:

```bash
bench setup add-domain
```

For example:

```bash
bench setup add-domain shipra.mp.gov.in
```

It will ask which site should receive that domain.

Frappe stores custom domain configuration in the site's `site_config.json`. ([Frappe Docs][6])

You can then inspect:

```bash
cat sites/<your-site>/site_config.json
```

You may see a structure containing:

```json
{
    "domains": [
        {
            "domain": "shipra.mp.gov.in"
        }
    ]
}
```

This is preferable to manually editing the generated Nginx configuration.

---

# 14. Enable DNS-based multitenancy

For hostname-based site selection:

```bash
bench config dns_multitenant on
```

Frappe's DNS-based multitenancy works by naming sites after the hostnames that resolve to them. Multiple sites can then share the same web endpoint and Frappe selects the appropriate site from the hostname. ([Frappe Docs][5])

For a single-site installation, this concept is still useful because your domain becomes the natural hostname for the site.

---

# 15. Configure DNS

This part happens outside Frappe.

Suppose the server's public IP is:

```text
203.0.113.50
```

Your DNS provider should have something like:

```text
Type: A
Name: shipra
Value: 203.0.113.50
```

Then:

```text
shipra.mp.gov.in
       │
       ▼
203.0.113.50
       │
       ▼
     Nginx
       │
       ▼
    Frappe
```

You can test DNS:

```bash
dig shipra.mp.gov.in
```

or:

```bash
nslookup shipra.mp.gov.in
```

You want it to resolve to the correct server.

---

# 16. Generate Nginx configuration

After adding/changing domains:

```bash
bench setup nginx
```

Frappe generates:

```text
config/nginx.conf
```

Frappe's production setup documentation recommends generating Nginx configuration with `bench setup nginx` and linking the generated configuration into Nginx's configuration directory. ([Frappe Docs][1])

For example:

```bash
sudo ln -s /home/inxeoz/pro/config/nginx.conf \
    /etc/nginx/conf.d/frappe-bench.conf
```

The exact Nginx directory can differ between distributions, so check:

```bash
ls /etc/nginx/
```

and:

```bash
ls /etc/nginx/conf.d/
```

---

# 17. Test Nginx configuration

Before reloading:

```bash
sudo nginx -t
```

You want:

```text
syntax is ok
test is successful
```

Only then:

```bash
sudo systemctl reload nginx
```

or:

```bash
sudo service nginx reload
```

Frappe's documentation similarly recommends regenerating Nginx configuration and reloading Nginx after domain configuration changes. ([Frappe Docs][6])

---

# 18. The complete domain flow

Once everything is configured, the request becomes:

```text
Browser
   │
   │ https://shipra.mp.gov.in
   ▼
DNS
   │
   │ server IP
   ▼
Nginx :443
   │
   │ Host: shipra.mp.gov.in
   ▼
Frappe :8000
   │
   │ hostname → site
   ▼
shipra.mp.gov.in
```

You no longer need:

```bash
curl -H "Host: localhost" ...
```

Instead:

```bash
curl http://shipra.mp.gov.in
```

or, with HTTPS:

```bash
curl https://shipra.mp.gov.in
```

---

# 19. HTTPS / SSL

For production, you should use HTTPS.

Frappe supports SSL configuration and can associate certificates with sites. Its documentation describes setting the certificate/key, regenerating Nginx configuration, and reloading Nginx. ([Frappe Docs][7])

For a Let's Encrypt-style setup, Frappe also provides:

```bash
bench setup lets-encrypt
```

and the Bench command reference lists SSL/Let's Encrypt functionality as part of the production tooling. ([Frappe Docs][8])

The desired production flow is:

```text
https://shipra.mp.gov.in
          │
          ▼
       Nginx :443
          │
       TLS/SSL
          │
          ▼
       Frappe :8000
```

---

# 20. Domain synchronization

Frappe Bench also has a specific command:

```bash
bench setup sync-domains
```

The Bench command reference describes `sync-domains` as checking for changes in domains and updating the domains list. ([Frappe Docs][8])

This is useful when domain configuration changes and you want Bench to synchronize its domain information.

A typical domain-management sequence is:

```bash
bench setup add-domain shipra.mp.gov.in
bench setup sync-domains
bench setup nginx
sudo nginx -t
sudo systemctl reload nginx
```

Depending on your Frappe/Bench version and whether you're using DNS-based multitenancy, not every installation requires every command every time. The key is that the **site/domain configuration, Nginx configuration, and DNS must agree**.

---

# 21. A useful production workflow

For your setup, I'd use this workflow.

### Application code changed

```bash
cd /home/inxeoz/pro

bench build

sudo supervisorctl restart all
```

### Domain changed

```bash
cd /home/inxeoz/pro

bench setup sync-domains
bench setup nginx

sudo nginx -t
sudo systemctl reload nginx
```

### Supervisor configuration changed

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl status
```

### Everything needs restarting

```bash
sudo supervisorctl restart all
```

### Full application update

```bash
bench update
```

Frappe documents `bench update` as the broader update operation that can pull applications, run patches, build assets and restart Supervisor-managed processes. ([Frappe Docs][3])

---

# 22. Troubleshooting checklist

## `supervisorctl status` returns nothing

Check:

```bash
sudo grep -n -A10 -B2 '\[include\]' /etc/supervisord.conf
```

If you have:

```ini
files = supervisord.d/*.ini
```

but your file is:

```text
frappe.conf
```

it won't be loaded.

Fix:

```text
frappe.conf
     ↓
frappe.ini
```

Then:

```bash
sudo supervisorctl reread
sudo supervisorctl update
```

---

## `reread` says nothing changed

Check:

```bash
sudo ls -la /etc/supervisord.d/
```

Make sure the Frappe configuration is actually there and matches the include pattern.

---

## Frappe returns:

```text
127.0.0.1 does not exist
```

The HTTP `Host` does not match a Frappe site.

Test:

```bash
curl -H "Host: your-site-name" http://127.0.0.1:8000
```

If that works, Frappe itself is probably fine; your hostname/domain routing is what needs configuration.

---

## Frappe works on `localhost` but not the domain

Check DNS:

```bash
dig shipra.mp.gov.in
```

Check Nginx:

```bash
sudo nginx -t
```

Check Nginx status:

```bash
sudo systemctl status nginx
```

Check Frappe:

```bash
sudo supervisorctl status
```

Check the domain directly against the local backend:

```bash
curl -H "Host: shipra.mp.gov.in" http://127.0.0.1:8000
```

If this works but:

```bash
curl http://shipra.mp.gov.in
```

doesn't, the problem is likely DNS/Nginx rather than Frappe.

---

# 23. Recommended final configuration

For your `/home/inxeoz/pro` setup, the important pieces should look like this:

```text
/home/inxeoz/pro/
│
├── apps/
├── config/
│   ├── supervisor.conf
│   ├── nginx.conf
│   ├── redis_cache.conf
│   └── redis_queue.conf
│
├── env/
│
├── logs/
│
└── sites/
    ├── common_site_config.json
    └── <your-site>/
```

Supervisor:

```text
/etc/supervisord.conf
        │
        └── supervisord.d/*.ini
                    │
                    ▼
             frappe.ini
                    │
                    ▼
       /home/inxeoz/pro/config/
             supervisor.conf
```

Nginx:

```text
/etc/nginx/
       │
       ▼
frappe-bench.conf
       │
       ▼
/home/inxeoz/pro/config/nginx.conf
```

DNS:

```text
shipra.mp.gov.in
       │
       ▼
server public IP
       │
       ▼
     Nginx
       │
       ▼
 Frappe :8000
```

Supervisor:

```text
supervisord
   │
   ├── Redis
   ├── Frappe Web
   ├── Socket.IO
   ├── Scheduler
   ├── Short Workers
   └── Long Workers
```

---

# 24. The most important commands to remember

If you only remember a handful of commands, keep these:

```bash
# Generate Supervisor configuration
bench setup supervisor

# Check Supervisor configuration
sudo supervisorctl reread

# Apply configuration changes
sudo supervisorctl update

# See Frappe processes
sudo supervisorctl status

# Restart Frappe
sudo supervisorctl restart all

# Build frontend assets
bench build

# Generate Nginx configuration
bench setup nginx

# Add a custom domain
bench setup add-domain shipra.mp.gov.in

# Synchronize domains
bench setup sync-domains

# Validate Nginx
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

Frappe officially provides the Supervisor, Nginx, domain, multitenancy and production setup commands used above. ([Frappe Docs][1])

## Final mental model

The easiest way to remember the whole setup is:

```text
                    DOMAIN
                      │
                      ▼
               shipra.mp.gov.in
                      │
                      ▼
                    DNS
                      │
                      ▼
                   NGINX
                  :80/:443
                      │
                      ▼
                Frappe :8000
                      │
             hostname → site
                      │
                      ▼
             ┌────────────────┐
             │     Frappe     │
             └────────────────┘
                │     │     │
                ▼     ▼     ▼
              Redis  Queue  Workers

            Supervisor
                 │
       keeps all of these alive
```

**DNS tells the world where the server is. Nginx receives the domain. Frappe maps the hostname to the site. Supervisor keeps the application processes running.**

That separation is the key to understanding the entire deployment.

[1]: https://docs.frappe.io/framework/user/en/bench/guides/setup-production?utm_source=chatgpt.com "Setup Production"
[2]: https://docs.frappe.io/framework/user/en/tutorial?utm_source=chatgpt.com "Install and Setup Bench"
[3]: https://docs.frappe.io/framework/user/en/production-setup?utm_source=chatgpt.com "Production Setup"
[4]: https://docs.supervisord.org/configuration.html?utm_source=chatgpt.com "Configuration File — Supervisor 4.3.0 documentation"
[5]: https://docs.frappe.io/framework/user/en/bench/guides/setup-multitenancy?utm_source=chatgpt.com "Setup Multitenancy"
[6]: https://docs.frappe.io/framework/user/en/bench/guides/adding-custom-domains?utm_source=chatgpt.com "Adding Custom Domains to your Site"
[7]: https://docs.frappe.io/framework/user/en/bench/guides/configuring-https?utm_source=chatgpt.com "Configuring HTTPS"
[8]: https://docs.frappe.io/framework/user/en/bench/bench-commands?utm_source=chatgpt.com "Bench Commands"
Supervisor

---
title: "How to Set Up Multiple Frappe Benches on One Machine"
date: 2026-06-23
draft: false
viewMode: docs
tags: ["frappe"]
categories: ["Tech"]
lightbox: true
---



Run two (or more) Frappe benches side-by-side — each with its own web server, Redis instances, and site — without port conflicts.

## Why

- Isolate development environments per project or per app.
- Run a stable bench alongside an experimental one.
- Test different Frappe versions or app branches concurrently.

## Overview

Each bench needs its own set of ports for:

| Service       | Default port | Notes                                        |
|---------------|-------------|----------------------------------------------|
| Web server    | 8000        | `webserver_port` in `common_site_config.json` |
| Redis cache   | 13000       | `redis_cache.conf` → `port`                  |
| Redis queue   | 11000       | `redis_queue.conf` → `port`                  |
| Redis socketio| 12000       | `redis_socketio.conf` → `port` (create it)   |
| SocketIO      | 9000        | `socketio_port` in `common_site_config.json`  |

Second bench increments each by 1 (or any offset): 8001, 13001, 11001, 12001, 9002.

## Step by step

### 1. Create the second bench

```bash
bench init ~/Work/bench-two
cd ~/Work/bench-two
bench get-app https://github.com/your/app.git
bench new-site site2
bench use site2
```

### 2. Assign unique ports

Set the web server and socketio ports in the bench's global config:

```bash
bench set-config -g webserver_port 8001
bench set-config -g socketio_port 9002
```

Or edit `sites/common_site_config.json` directly:

```json
{
 "webserver_port": 8001,
 "socketio_port": 9002,
 "redis_cache": "redis://127.0.0.1:13001",
 "redis_queue": "redis://127.0.0.1:11001",
 "redis_socketio": "redis://127.0.0.1:12001"
}
```

### 3. Update Redis config files

**`config/redis_cache.conf`** — change `port`:

```
port 13001
```

**`config/redis_queue.conf`** — change `port`:

```
port 11001
```

**Create `config/redis_socketio.conf`** (doesn't exist by default):

```conf
dbfilename redis_socketio.rdb
dir /path/to/bench/config/pids
pidfile /path/to/bench/config/pids/redis_socketio.pid
bind 127.0.0.1
port 12001
```

> Use the same `dir` and `pidfile` paths as `redis_cache.conf` — only the filename differs.

### 4. Update the Procfile

Add the `redis_socketio` entry and set the web port:

```procfile
redis_cache: redis-server config/redis_cache.conf
redis_queue: redis-server config/redis_queue.conf
redis_socketio: redis-server config/redis_socketio.conf
web: bench serve --port 8001
socketio: node apps/frappe/socketio.js
watch: bench watch
schedule: bench schedule
worker: bench worker 1>> logs/worker.log 2>> logs/worker.error.log
```

### 5. Start the bench

```bash
honcho start -f Procfile
```

Or if `honcho` isn't on your PATH:

```bash
~/.local/share/pipx/venvs/frappe-bench/bin/honcho start -f Procfile
```

### 6. Verify

```bash
# Web server
curl -sI http://127.0.0.1:8001/ | head -3
# -> HTTP/1.1 200 OK

# Redis instances
redis-cli -p 13001 PING   # -> PONG
redis-cli -p 11001 PING   # -> PONG
redis-cli -p 12001 PING   # -> PONG
```

Each bench is fully independent — separate Redis data, separate worker queues, separate sites.

## nginx (optional)

To serve through nginx on a different port, generate the config with `bench setup nginx` and update the upstream port to match your webserver port. The generated config will be at `config/nginx.conf`.

## Port conflicts

If a port is already in use, pick a different offset. Common conflicts:

- **SocketIO port** — only one process can bind a port. Give each bench its own (9000, 9002, 9003…).
- **Redis ports** — each bench gets its own trio. Keep them separate.
- **Web port** — obvious. Running `bench serve --port 8001` explicitly in the Procfile avoids surprises if `common_site_config.json` changes.

## Stopping

```bash
# Kill all processes for a bench
pkill -f "path/to/bench/env/bin/python.*frappe"
# Kill its redis instances
fuser -k 13001/tcp 11001/tcp 12001/tcp
# Kill its node socketio
fuser -k 9002/tcp
```

Or simply `Ctrl+C` the `honcho` process.

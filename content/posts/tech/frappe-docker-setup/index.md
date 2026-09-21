---
title: "Frappe Docker Setup (Custom Image + App)"
date: 2026-05-21
draft: false
tags: ["frappe", "docker", "frappe-docker"]
categories: ["Tech"]
viewMode: docs
---

Based on [frappe_docker](https://github.com/frappe/frappe_docker)

This guide walks through deploying a custom Frappe app using Docker — from cloning frappe_docker and building a custom image with your app baked in, to spinning up containers and creating the first site. It also covers offline/air-gapped deployment for servers without internet access.

---

## 1. Clone Repository

```bash
mkdir frappe-wiki
cd frappe-wiki
git clone --depth 1 https://github.com/frappe/frappe_docker .
```

---

## 2. Define Apps (`apps.json`)

```json
[
  {
    "url": "https://github.com/frappe/wiki",
    "branch": "develop"
  }
]
```

---

## 3. Build Custom Image

### Recommended (BuildKit)

```bash
docker build \
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg=FRAPPE_BRANCH=version-16 \
  --secret=id=apps_json,src=apps.json \
  --tag=custom:16 \
  --file=images/layered/Containerfile .
```

### For Older Docker Versions

```bash
export APPS_JSON_BASE64=$(base64 -w 0 apps.json)

docker build \
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg=FRAPPE_BRANCH=version-16 \
  --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
  --tag=custom:16 \
  --file=images/layered/Containerfile .
```

---

## 4. Environment Configuration (`custom.env`)

```bash
ERPNEXT_VERSION=v16.13.0
DB_PASSWORD=123
FRAPPE_SITE_NAME_HEADER=wiki.localhost
HTTP_PUBLISH_PORT=8072

CUSTOM_IMAGE=custom
CUSTOM_TAG=16
PULL_POLICY=missing
```

---

## 5. Generate Compose File

```bash
docker compose --env-file custom.env \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.noproxy.yaml \
  config > compose.custom.yaml
```

---

### Offline / Air-Gapped Setup

Steps 1–5 can be done locally (if server doesn't have internet connection).

1. **Export and compress image**
   ```bash
   docker save -o container_image.tar custom:16
   zip container_image.tar.zip container_image.tar
   ```

2. **Copy to server**
   Copy `container_image.tar.zip`, `custom.env`, and `compose.custom.yaml` to a project-named folder on the server.

3. **Verify files**
   ```bash
   ls
   # compose.custom.yaml  container_image.tar.zip  custom.env
   ```

4. **Load image on server**
   ```bash
   unzip container_image.tar.zip
   docker load -i container_image.tar
   ```

---

## 6. Reset Existing Deployment (if Exists)

```bash
docker compose -p frappe-wiki -f compose.custom.yaml down
```

> Avoid `-v` — this destroys volumes with all container data.
> `-p frappe-wiki` is the project name; each project should have a unique name.

---

## 7. Start Containers

```bash
docker compose -p frappe-wiki -f compose.custom.yaml up -d
```

---

## 8. Verify Containers

```bash
docker ps | grep frappe-wiki
```

Expected: containers running with port mapping `8072 → 8080`

---

## 9. Setup Site and Install App

### Enter Backend Container

```bash
docker compose -p frappe-wiki -f compose.custom.yaml exec backend bash
```

---

### Create Site

```bash
bench new-site wiki.localhost
```

When prompted:

```
MariaDB root user: root
Password: 123
```

(db password from `custom.env`)

---

### Set Default Site

```bash
bench use wiki.localhost
```

---

### Install App

```bash
bench install-app wiki
```

---

### Restart

```bash
bench restart
```

---

## 10. Access Application

Test locally:

```bash
curl localhost:8072 | head -10
```

If response shows `"does not exist"`:

```bash
curl -H "Host: wiki.localhost" localhost:8072 | head -10
```

---

## 11. Network Access

```bash
curl <public_or_network_ip>:8072 | head -10
```

or

```bash
curl -H "Host: wiki.localhost" <public_or_network_ip>:8072 | head -10
```

Examples: `172.18.x.x`, `10.x.x.x`

---

## 12. Open Firewall (RHEL/CentOS)

```bash
sudo firewall-cmd --zone=public --add-port=8072/tcp --permanent
sudo firewall-cmd --reload
```

---

## Troubleshooting

### Site Not Resolving

Use Host header:

```bash
curl -H "Host: wiki.localhost" localhost:8072
```

---

### Database Connection Issues

Run inside backend container:

```bash
bench new-site wiki.localhost \
  --db-host mariadb \
  --mariadb-root-password 123 \
  --admin-password admin_password_here
```

---

### If Still Not Working

- Verify containers are running
- Check logs:
  ```bash
  docker compose -p frappe-wiki -f compose.custom.yaml logs
  ```
- Ensure port `8072` is open

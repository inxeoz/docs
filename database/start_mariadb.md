---
title: Start Mariadb
date: 2025-11-20T16:01:16Z
lastmod: 2025-11-20T16:01:16Z
description: MariaDB Docker container configuration
permalink: posts/{{ title | slug }}/index.html
tags: [docker, mariadb, database]
---

docker run -d \
  --name mariadb \
  --network frappe-net \
  -e MYSQL_ROOT_PASSWORD=frappe \
  -e MYSQL_USER=frappe \
  -e MYSQL_PASSWORD=frappe \
  -e MYSQL_DATABASE=frappe \
  -v mariadb_data:/var/lib/mysql \
  -p 3307:3306 \
  mariadb:10.6

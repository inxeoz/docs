---
title: "How to Set Up CI/CD for Frappe When Your Server Has No Internet"
date: 2026-07-26
draft: false
tags: ["frappe", "ci-cd", "jenkins", "docker", "offline", "air-gapped", "deployment"]
categories: ["Tech"]
viewMode: docs
showToc: true
---

Frappe Bench applications require schema migrations, Docker images, and database backups. When the production server has no internet access, you need a CI/CD pipeline that builds locally, ships artifacts offline, and supports one-click rollback.

This guide covers a Jenkins-based pipeline that does exactly that.

## The Problem

- Frappe apps require schema migrations
- Docker images must be deployed without pulling from the internet
- Rollback must restore both code and database
- Deployment must be repeatable, auditable, and safe

## Architecture

```
Developer → Git Push
        ↓
Jenkins (Internet Allowed)
        ↓
Build Docker Image
        ↓
docker save → image.tar
        ↓
scp → Offline Server
        ↓
docker load + docker compose up
        ↓
bench migrate
```

Rollback:

```
Load old image.tar
Restore matching DB backup
Restart containers
```

## Repository Structure

```
.
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── apps/
│   └── custom_app
└── Jenkinsfile
```

Do NOT commit `sites/`, logs, or secrets.

## Dockerfile

All dependencies must be installed at build time:

```dockerfile
FROM frappe/bench:latest

RUN apt-get update && apt-get install -y \
    mariadb-client \
    wkhtmltopdf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

## entrypoint.sh

```bash
#!/bin/bash
set -e

bench migrate
bench clear-cache

exec "$@"
```

This prevents half-applied migrations and fails fast if migration breaks.

## docker-compose.yml

```yaml
version: "3"

services:
  backend:
    image: frappe_app:${VERSION}
    container_name: frappe_backend
    restart: always
```

Jenkins controls the image version using `${VERSION}`.

## Jenkins Setup

### Required Plugins

- Git
- Pipeline
- SSH Agent
- Credentials Binding

### SSH Access

From Jenkins server:

```bash
ssh-keygen -t ed25519
ssh-copy-id deployer@frappe-server.local
```

Test:

```bash
ssh deployer@frappe-server.local
```

## Jenkinsfile (Full CI/CD Pipeline)

```groovy
pipeline {
  agent any

  environment {
    IMAGE_NAME = "frappe_app"
    VERSION = "${env.BUILD_NUMBER}"
    SERVER = "deployer@frappe-server.local"
    BASE_DIR = "/opt/frappe"
  }

  stages {

    stage('Checkout') {
      steps {
        git branch: 'main',
            url: 'git@github.com:your-org/frappe-app.git'
      }
    }

    stage('Build Image') {
      steps {
        sh "docker build -t ${IMAGE_NAME}:${VERSION} ."
      }
    }

    stage('Save Image') {
      steps {
        sh "docker save ${IMAGE_NAME}:${VERSION} -o ${IMAGE_NAME}_${VERSION}.tar"
      }
    }

    stage('Backup Database') {
      steps {
        sh """
        ssh ${SERVER} '
          mkdir -p ${BASE_DIR}/backups/${VERSION} &&
          docker exec frappe_backend \
            bench backup --with-files \
            --backup-path ${BASE_DIR}/backups/${VERSION}
        '
        """
      }
    }

    stage('Copy Image') {
      steps {
        sh """
        scp ${IMAGE_NAME}_${VERSION}.tar \
        ${SERVER}:${BASE_DIR}/images/
        """
      }
    }

    stage('Deploy') {
      steps {
        sh """
        ssh ${SERVER} '
          docker load < ${BASE_DIR}/images/${IMAGE_NAME}_${VERSION}.tar &&
          export VERSION=${VERSION} &&
          cd ${BASE_DIR} &&
          docker compose up -d
        '
        """
      }
    }
  }
}
```

## Versioned Storage on Server

```
/opt/frappe/
├── images/
│   ├── frappe_app_41.tar
│   ├── frappe_app_42.tar
├── backups/
│   ├── 41/
│   ├── 42/
```

Image version matches DB backup version. Deterministic rollback.

## Rollback Strategy

**Golden Rule:** Never rollback image without restoring matching DB backup.

### Jenkins Rollback Job

```groovy
pipeline {
  agent any

  parameters {
    string(name: 'ROLLBACK_VERSION', description: 'Version to rollback')
  }

  stages {
    stage('Rollback') {
      steps {
        sh """
        ssh deployer@frappe-server.local '
          cd /opt/frappe &&
          docker compose down &&
          docker load < images/frappe_app_${ROLLBACK_VERSION}.tar &&
          docker exec frappe_backend \
            bench restore backups/${ROLLBACK_VERSION}/site.sql.gz --force &&
          docker compose up -d
        '
        """
      }
    }
  }
}
```

Rollback time: ~1 minute.

## Retention Policy

Keep last 5 versions only:

```bash
ls -t images/frappe_app_*.tar | tail -n +6 | xargs rm -f
ls -t backups | tail -n +6 | xargs rm -rf
```

## Common Mistakes

- Using `latest` image tag
- Running migrations manually
- Skipping DB backup
- Pulling images on offline server
- Assuming Frappe supports downgrade migrations

## Checklist

- Jenkins Pipeline configured
- Docker image versioning working
- Offline deployment tested
- Pre-migration DB backup verified
- One-click rollback tested
- Auditable history in Jenkins

## Conclusion

This CI/CD design is enterprise-grade, offline-safe, rollback-ready, and Frappe-compatible. It is the recommended way to deploy Frappe Bench in restricted environments.

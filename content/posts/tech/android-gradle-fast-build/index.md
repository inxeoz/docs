---
title: "Lightning Fast Android & Gradle Builds"
date: 2026-05-31
draft: false
viewMode: docs
tags: ["android", "gradle", "kotlin", "performance", "build-tools"]
categories: ["Tech"]
showToc: true
---

Waiting 3–5 minutes for every Gradle build is a productivity killer. Here's every optimisation I apply to cut build times down to seconds — not minutes.

On my machine: **20GB RAM + 12th Gen Intel Core i3** (4 P-cores, no E-cores). These settings are tuned to squeeze every drop of performance out of that hardware.

## The One-Shot Config

Drop this into your project-level `gradle.properties`. Tuned for 20GB RAM + 12th Gen Intel.

```properties
# =====================================================================
# MAX PERFORMANCE — 20GB / 12th Gen Intel
# =====================================================================

# 1. CORE EXECUTION OPTIMISATIONS
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true
org.gradle.vfs.watch=true

# 2. HARDWARE & WORKER TUNING
org.gradle.workers.max=4

# 3. ADVANCED JVM & MEMORY MANAGEMENT
org.gradle.jvmargs=-Xmx8g -XX:+UseG1GC -XX:+ParallelRefProcEnabled \
  -XX:MaxInlineLevel=30 -XX:+AlwaysPreTouch \
  -Dsun.rmi.dgc.server.gcInterval=3600000 \
  -Dsun.rmi.dgc.client.gcInterval=3600000

# 4. KOTLIN DAEMON — separate heap, don't compete with Gradle
kotlin.daemon.jvmargs=-Xmx4g -XX:+UseG1GC

# 5. ANDROID-SPECIFIC
android.enableJetifier=false
android.useAndroidX=true
```

## 1. Core Execution Optimisations

### `org.gradle.daemon=true`
Keeps the Gradle runner alive in the background. Without this, every build pays a ~5–10s JVM startup cost.

### `org.gradle.parallel=true`
Enables parallel compilation for multi-module projects. Independent modules build concurrently instead of one-at-a-time.

### `org.gradle.caching=true`
Reuses outputs from previous builds. If nothing changed in a module, Gradle skips it entirely — no recompilation, no re-testing. Combined with a remote cache (e.g. `org.gradle.caching.http`) your CI can share artifacts with local dev machines.

### `org.gradle.configureondemand=true`
Only configures modules **relevant to the requested task**. If you're building `:app`, Gradle won't waste time configuring `:some-library-module` you never touch.

### `org.gradle.vfs.watch=true`
Keeps file-system state in memory between builds. Gradle won't re-scan the entire file tree to detect changes — it watches for OS-level file events instead. Shaves 3–8s off incremental builds.

> **Linux:** Bump `fs.inotify.max_user_watches` — `sudo sysctl -w fs.inotify.max_user_watches=524288` and add it to `/etc/sysctl.conf`.

## 2. Worker Tuning — 12th Gen i3

12th Gen i3 has **4 P-cores**, no E-cores. Gradle workers should match your **physical core count**.

| CPU           | P-cores | `workers.max` |
|---------------|---------|---------------|
| i3-12100(F)   | 4       | `4`           |
| i5-12400      | 6       | `6`           |
| i7-12700K     | 8       | `8`           |
| i9-12900K     | 8       | `8`           |

With only 4 cores, every thread counts. Going above `4` causes context-switch overhead that slows things down — hyper-threads don't help Gradle's CPU-bound compilation.

## 3. JVM & Memory — 20GB RAM

```properties
org.gradle.jvmargs=-Xmx8g -XX:+UseG1GC -XX:+ParallelRefProcEnabled \
  -XX:MaxInlineLevel=30 -XX:+AlwaysPreTouch \
  -Dsun.rmi.dgc.server.gcInterval=3600000 \
  -Dsun.rmi.dgc.client.gcInterval=3600000
```

| Flag | What it does |
|------|-------------|
| `-Xmx8g` | **8GB heap** for the Gradle daemon. With 20GB total, this leaves plenty for AS, Kotlin daemon, and OS. |
| `-XX:+UseG1GC` | Low-pause garbage collector. Scales well with large heaps. |
| `-XX:+ParallelRefProcEnabled` | Process references (SoftReference, WeakReference) in parallel during GC. |
| `-XX:MaxInlineLevel=30` | More aggressive JIT inlining. Gradle/Groovy/Kotlin compiler calls a *lot* of small methods — deeper inlining means faster execution. Default is 9. |
| `-XX:+AlwaysPreTouch` | **Pre-allocates and touches** all heap pages at JVM startup. Instead of slowly faulting pages in during the build (causing micro-stutters), it maps them upfront. Adds ~1s to daemon start, removes GC jitter during compilation. |
| `sun.rmi.dgc.*` | Prevents distributed GC from forcing full GC cycles every hour. |

**Why 8g and not 10g or 12g?** The Kotlin daemon gets its own 4g heap (`kotlin.daemon.jvmargs=-Xmx4g`). That's 12g total for build processes — leaving ~8g for Android Studio, IDE indexing, Chrome tabs, and the OS. If you close everything else, you could push Gradle to `-Xmx10g`, but 8g is the sweet spot for real-world usage.

## 4. Kotlin Daemon Isolation

```properties
kotlin.daemon.jvmargs=-Xmx4g -XX:+UseG1GC
```

The Kotlin daemon is a separate JVM process. Giving it its own heap prevents it from competing with the Gradle daemon for memory. With 4g, it can hold the entire compiled symbol table in memory across builds — no re-indexing, no GC thrashing.

> **Verify it's working:** Run a build, then `jps -l`. You should see two JVMs — `GradleDaemon` and `KotlinCompileDaemon`.

## 5. Android-Specific Flags

### `android.useAndroidX=true`
Required if you're on AndroidX.

### `android.enableJetifier=false`
Jetifier rewrites old support-library deps at build time. If **every** dependency is already AndroidX, this is wasted CPU.

Check:

```bash
./gradlew app:dependencies --configuration debugRuntimeClasspath \
  | grep -i "support"
```

Nothing → set `false`. Reclaim that CPU time for actual compilation.

## 6. Module Structure Matters

Gradle can only parallelise what's **independent**. A flat module graph is faster than a deep dependency tree.

```
❌ Bad                          ✅ Good
:app ──> :core                  :app ──> :core
  └──> :feature-a                 └──> :feature-a ──> :core
  └──> :feature-b                 └──> :feature-b ──> :core  
```

`feature-a` and `feature-b` build in parallel when they only depend on `:core`.

## 7. IDE & System Tweaks

- **Disable unused plugins** — `google-services`, `kotlin-android-extensions` (deprecated), etc.
- **Android Studio** → `Help > Edit Custom VM Options` → bump `-Xmx` to `4096m` or `5120m` (you have the RAM).
- **Exclude build/ directories** from any antivirus/backup watcher (also Windows Defender / `updatedb`). Gradle writes and deletes temp files constantly.
- **Power plan** → High Performance. 12th gen E-cores are great for battery life but you want P-cores doing the heavy lifting.

## 8. Measure First

```bash
./gradlew assembleDebug --scan
```

The Build Scan shows task durations, cache misses, GC pauses, and configuration time. Run it before and after every change.

---

Apply these, run the first full build (slower — caches are cold), then enjoy 5–15s incremental builds. Your Ctrl+F9 will thank you.

# Export Only Changed Files From Git (Branches or Commits) While Preserving Folder Structure

Sometimes you need to export only the files changed in Git instead of sharing the entire project. This is useful for deployments, patch updates, code reviews, or sharing incremental changes.

This guide explains how to export only affected files while keeping the original folder structure intact.

---

# What This Method Does

This approach exports:

* modified files
* newly added files
* renamed files

while preserving the original folder hierarchy.

It does NOT export:

* unchanged files
* deleted files
* `.git` history
* unnecessary project files

The exported files are the latest/final versions from the target branch or commit.

---

# Project Example

Suppose your project structure is:

```bash id="yqlu4m"
backend/
frontend/
knowledge/
```

You want an export like:

```bash id="3c0gtr"
exported_changes/
├── backend/
├── frontend/
└── knowledge/
```

but containing only changed files.

---

# Method 1 — Export Changes Between Branches

This method compares two branches.

Example:

```bash id="m73k2w"
master  -> base branch
d30     -> feature branch
```

---

## Step 1 — View Changed Files

Run:

```bash id="m34xf7"
git diff --name-status master d30
```

Example output:

```bash id="5hxw4n"
M backend/app/main.py
A frontend/src/pages/appeals/EditAppeal.jsx
R100 dia.md knowledge/dia.md
```

---

## Understanding the Output

| Symbol | Meaning        |
| ------ | -------------- |
| `M`    | Modified file  |
| `A`    | Added/new file |
| `R100` | Renamed file   |

---

## Step 2 — Create Export Folder

```bash id="8s4mlo"
mkdir exported_changes
```

---

## Step 3 — Copy Only Changed Files

Run:

```bash id="mbd0c4"
git diff --name-only master d30 | \
xargs -I{} cp --parents "{}" exported_changes/
```

This copies only changed files while preserving the original folder structure.

---

## Step 4 — Generate Change Summary (Optional)

```bash id="wux4e7"
git diff --name-status master d30 > exported_changes/CHANGELOG.txt
```

---

## Step 5 — Compress the Export

```bash id="07lw3l"
zip -r exported_changes.zip exported_changes
```

You now have:

```bash id="hyffu5"
exported_changes.zip
```

ready to share or deploy.

---

# Method 2 — Export Changes From Current Branch Against Master

If you are already on the feature branch, you do not need to specify the target branch explicitly.

Example:

```bash id="3rwlto"
* d30
  master
```

Verify current branch:

```bash id="7jq9sp"
git branch
```

---

## View Changes

```bash id="zuv7yv"
git diff --name-status master
```

This compares:

```bash id="ly6t68"
master -> current branch
```

---

## Export Changed Files

```bash id="f98yzt"
mkdir exported_changes

git diff --name-only master | \
xargs -I{} cp --parents "{}" exported_changes/
```

---

## Generate Changelog

```bash id="jvhc6n"
git diff --name-status master > exported_changes/CHANGELOG.txt
```

---

## Create Zip

```bash id="ff9jkl"
zip -r exported_changes.zip exported_changes
```

---

# Method 3 — Export Changes Between Two Commits

Sometimes you want to export changes between specific commits instead of branches.

Example:

```bash id="rj2ymf"
7bc6077 -> base commit
57cbe7a -> latest commit
```

---

## Step 1 — View Changed Files

```bash id="l5zz5u"
git diff --name-status 7bc6077 57cbe7a
```

Example output:

```bash id="wh1rk8"
M backend/app/main.py
A frontend/src/pages/appeals/EditAppeal.jsx
```

---

## Step 2 — Create Export Folder

```bash id="x59n9k"
mkdir exported_changes
```

---

## Step 3 — Export Changed Files

```bash id="ly72ck"
git diff --name-only 7bc6077 57cbe7a | \
xargs -I{} cp --parents "{}" exported_changes/
```

---

## Step 4 — Generate Changelog

```bash id="m7ymrm"
git diff --name-status 7bc6077 57cbe7a > exported_changes/CHANGELOG.txt
```

---

## Step 5 — Compress Export

```bash id="r40r91"
zip -r exported_changes.zip exported_changes
```

---

# Example Result

Suppose these files changed:

```bash id="3h1ji2"
backend/app/main.py
frontend/src/App.jsx
frontend/src/pages/appeals/EditAppeal.jsx
```

The exported folder becomes:

```bash id="o8a5ku"
exported_changes/
├── backend/
│   └── app/
│       └── main.py
└── frontend/
    └── src/
        ├── App.jsx
        └── pages/
            └── appeals/
                └── EditAppeal.jsx
```

Only affected files are included.

---

# macOS Alternative

Some macOS systems do not support:

```bash id="hlyd9u"
cp --parents
```

Use this alternative:

```bash id="6pksu7"
git archive d30 $(git diff --name-only master d30) | tar -x -C exported_changes
```

Or for commits:

```bash id="0xj5zg"
git archive 57cbe7a $(git diff --name-only 7bc6077 57cbe7a) | tar -x -C exported_changes
```

---

# Complete One-Line Solutions

## Branch Comparison

```bash id="klndsh"
mkdir exported_changes && \
git diff --name-only master d30 | \
xargs -I{} cp --parents "{}" exported_changes/ && \
git diff --name-status master d30 > exported_changes/CHANGELOG.txt && \
zip -r exported_changes.zip exported_changes
```

---

## Current Branch vs Master

```bash id="qvlk3s"
mkdir exported_changes && \
git diff --name-only master | \
xargs -I{} cp --parents "{}" exported_changes/ && \
git diff --name-status master > exported_changes/CHANGELOG.txt && \
zip -r exported_changes.zip exported_changes
```

---

## Commit Comparison

```bash id="p7v0z5"
mkdir exported_changes && \
git diff --name-only 7bc6077 57cbe7a | \
xargs -I{} cp --parents "{}" exported_changes/ && \
git diff --name-status 7bc6077 57cbe7a > exported_changes/CHANGELOG.txt && \
zip -r exported_changes.zip exported_changes
```

---

# Final Result

You end up with:

```bash id="01ccm7"
exported_changes.zip
```

containing:

* only changed files
* preserved folder structure
* optional changelog
* ready for deployment, review, or sharing

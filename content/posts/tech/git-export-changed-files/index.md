---
title: "Export Only Changed Files From Git While Preserving Folder Structure"
date: 2026-07-26
draft: false
tags: ["git", "deployment", "linux", "devops"]
categories: ["Tech"]
viewMode: docs
showToc: true
---

Sometimes you need to export only the files changed in Git instead of sharing the entire project. This is useful for deployments, patch updates, code reviews, or sharing incremental changes.

This guide explains how to export only affected files while keeping the original folder structure intact.

## What This Method Does

This approach exports:
- Modified files
- Newly added files
- Renamed files

While preserving the original folder hierarchy.

It does NOT export:
- Unchanged files
- Deleted files
- `.git` history
- Unnecessary project files

The exported files are the latest versions from the target branch or commit.

## Project Example

Suppose your project structure is:

```
backend/
frontend/
knowledge/
```

You want an export like:

```
exported_changes/
├── backend/
├── frontend/
└── knowledge/
```

but containing only changed files.

## Method 1: Export Changes Between Branches

This method compares two branches.

Example:

```
main    -> base branch
feature -> feature branch
```

### Step 1: View Changed Files

```bash
git diff --name-status main feature
```

Example output:

```
M backend/app/main.py
A frontend/src/pages/dashboard/EditDashboard.jsx
R100 notes.md knowledge/notes.md
```

### Understanding the Output

| Symbol | Meaning |
|--------|---------|
| `M` | Modified file |
| `A` | Added/new file |
| `R100` | Renamed file |

### Step 2: Create Export Folder

```bash
mkdir exported_changes
```

### Step 3: Copy Only Changed Files

```bash
git diff --name-only main feature | \
xargs -I{} cp --parents "{}" exported_changes/
```

### Step 4: Generate Change Summary (Optional)

```bash
git diff --name-status main feature > exported_changes/CHANGELOG.txt
```

### Step 5: Compress the Export

```bash
zip -r exported_changes.zip exported_changes
```

## Method 2: Export Changes From Current Branch Against Main

If you are already on the feature branch:

```bash
git diff --name-status main
```

Export:

```bash
mkdir exported_changes

git diff --name-only main | \
xargs -I{} cp --parents "{}" exported_changes/

git diff --name-status main > exported_changes/CHANGELOG.txt
zip -r exported_changes.zip exported_changes
```

## Method 3: Export Changes Between Two Commits

```bash
git diff --name-status abc1234 def5678
```

Export:

```bash
mkdir exported_changes

git diff --name-only abc1234 def5678 | \
xargs -I{} cp --parents "{}" exported_changes/

git diff --name-status abc1234 def5678 > exported_changes/CHANGELOG.txt
zip -r exported_changes.zip exported_changes
```

## Example Result

Suppose these files changed:

```
backend/app/main.py
frontend/src/App.jsx
frontend/src/pages/dashboard/EditDashboard.jsx
```

The exported folder becomes:

```
exported_changes/
├── backend/
│   └── app/
│       └── main.py
└── frontend/
    └── src/
        ├── App.jsx
        └── pages/
            └── dashboard/
                └── EditDashboard.jsx
```

Only affected files are included.

## macOS Alternative

Some macOS systems do not support `cp --parents`. Use this instead:

```bash
git archive feature $(git diff --name-only main feature) | tar -x -C exported_changes
```

Or for commits:

```bash
git archive def5678 $(git diff --name-only abc1234 def5678) | tar -x -C exported_changes
```

## Complete One-Line Solutions

### Branch Comparison

```bash
mkdir exported_changes && \
git diff --name-only main feature | \
xargs -I{} cp --parents "{}" exported_changes/ && \
git diff --name-status main feature > exported_changes/CHANGELOG.txt && \
zip -r exported_changes.zip exported_changes
```

### Current Branch vs Main

```bash
mkdir exported_changes && \
git diff --name-only main | \
xargs -I{} cp --parents "{}" exported_changes/ && \
git diff --name-status main > exported_changes/CHANGELOG.txt && \
zip -r exported_changes.zip exported_changes
```

### Commit Comparison

```bash
mkdir exported_changes && \
git diff --name-only abc1234 def5678 | \
xargs -I{} cp --parents "{}" exported_changes/ && \
git diff --name-status abc1234 def5678 > exported_changes/CHANGELOG.txt && \
zip -r exported_changes.zip exported_changes
```

## Summary

| Scenario | Command |
|----------|---------|
| Branch vs branch | `git diff --name-only branch1 branch2` |
| Current branch vs main | `git diff --name-only main` |
| Commit vs commit | `git diff --name-only sha1 sha2` |
| macOS alternative | `git archive` + `tar` |

You end up with a zip containing only changed files, preserved folder structure, optional changelog — ready for deployment, review, or sharing.

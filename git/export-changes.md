# Export Only Changed Files From a Git Branch While Preserving Folder Structure

Sometimes you need to share, deploy, or review only the files changed in a feature branch instead of sending the entire project. This guide explains how to export only the affected files while keeping the original directory structure intact.

This approach is useful for:

* deployment handovers
* patch releases
* code reviews
* manual server updates
* sharing work without the `.git` repository

---

# Scenario

Suppose:

```bash id="jov2g5"
master  -> base branch
d30     -> feature branch
```

You want to export:

* only changed files
* modified and newly added files
* original folder hierarchy
* ready-to-share package

---

# Understanding the Goal

Assume your project structure looks like this:

```bash id="4ztbyx"
backend/
frontend/
knowledge/
```

After exporting, you want something like:

```bash id="t5oqbz"
exported_changes/
├── backend/
├── frontend/
└── knowledge/
```

But only with files that changed between `master` and `d30`.

---

# Method 1 — When You Are Already on the Feature Branch

If you are currently on the feature branch (`d30`), this is the simplest method.

---

## Step 1 — Verify Current Branch

Check your current branch:

```bash id="rq1gx5"
git branch
```

Example:

```bash id="54jx2q"
* d30
  master
```

The `*` indicates the active branch.

---

## Step 2 — See What Changed Compared to Master

Run:

```bash id="6rrf6g"
git diff --name-status master
```

Example output:

```bash id="0a8wvh"
M backend/app/main.py
A frontend/src/pages/appeals/EditAppeal.jsx
R100 dia.md knowledge/dia.md
```

### Meaning of Symbols

| Symbol | Meaning        |
| ------ | -------------- |
| `M`    | Modified file  |
| `A`    | Added/new file |
| `R100` | Renamed file   |

---

## Step 3 — Create Export Folder

```bash id="8kt8ij"
mkdir exported_changes
```

---

## Step 4 — Copy Only Changed Files

Run:

```bash id="s81m3w"
git diff --name-only master | xargs -I{} cp --parents "{}" exported_changes/
```

This copies only changed files into `exported_changes/` while preserving the original directory structure.

---

## Step 5 — Verify Export

Check the folder:

```bash id="b5f6l0"
ls exported_changes
```

You should see:

```bash id="38gvhy"
backend/
frontend/
knowledge/
```

---

## Step 6 — Generate a Change Summary (Optional)

Create a changelog file:

```bash id="9q9u6h"
git diff --name-status master > exported_changes/CHANGELOG.txt
```

This is useful for deployments and documentation.

---

## Step 7 — Compress the Export

Zip everything:

```bash id="x32krk"
zip -r exported_changes.zip exported_changes
```

You now have:

```bash id="j2c0i0"
exported_changes.zip
```

ready to share or deploy.

---

# Method 2 — Compare Two Branches Explicitly

If you are NOT currently on the feature branch, compare branches directly.

Example:

```bash id="1bgmzl"
git diff --name-status master d30
```

Export files using:

```bash id="6j13eu"
mkdir exported_changes

git diff --name-only master d30 | \
xargs -I{} cp --parents "{}" exported_changes/
```

---

# Method 3 — Compare Specific Commits

You can also compare exact commits.

Example:

```bash id="w7ulq7"
git diff --name-status 7bc6077 57cbe7a
```

Export changed files:

```bash id="8x3hyq"
mkdir exported_changes

git diff --name-only 7bc6077 57cbe7a | \
xargs -I{} cp --parents "{}" exported_changes/
```

This is useful when you want precise control over the export range.

---

# What Gets Exported?

This method exports:

* modified files
* newly added files
* renamed files

It does NOT export:

* unchanged files
* deleted files
* git history
* `.git` directory

The exported files are the latest/final versions from the target branch.

---

# Example

Suppose these files changed:

```bash id="iz5u42"
backend/app/main.py
frontend/src/App.jsx
frontend/src/pages/appeals/EditAppeal.jsx
```

After export:

```bash id="eb7w6k"
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

```bash id="lw6ru6"
cp --parents
```

Use this alternative:

```bash id="9a5r95"
git archive d30 $(git diff --name-only master d30) | tar -x -C exported_changes
```

---

# Full One-Line Solution

If you are currently on the feature branch:

```bash id="rkh75x"
mkdir exported_changes && \
git diff --name-only master | \
xargs -I{} cp --parents "{}" exported_changes/ && \
git diff --name-status master > exported_changes/CHANGELOG.txt && \
zip -r exported_changes.zip exported_changes
```

---

# Final Result

You end up with:

```bash id="p8b4xg"
exported_changes.zip
```

containing:

* only changed files
* preserved folder structure
* optional changelog
* ready for deployment or sharing

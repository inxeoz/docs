---
title: "Fixing Frappe DocTypes After a Restore Without Source Code"
date: 2026-07-26
draft: false
tags: ["frappe", "erpnext", "doctype", "restore", "database", "docker"]
categories: ["Tech"]
viewMode: docs
showToc: true
---

You restored a Frappe database backup and now every custom DocType returns `Module Not Found` or `The resource you are looking for is not available`. The database has all the data, but Frappe can't find the controller files.

This happens because Frappe DocTypes can exist in two states, and the restore process doesn't always match what Frappe expects. Here's how to diagnose and fix it.

## The Root Cause

Frappe DocTypes have a `custom` flag:

| Flag | State | Requirements |
|------|-------|-------------|
| `custom = 0` | Standard DocType | Needs controller files (`.py`, `.js`, `.json`) in the app folder |
| `custom = 1` | Custom DocType | Uses database schema only; no controller files needed |

When you restore from a backup without the original app source code, Frappe sees `custom = 0` and looks for files at `apps/[app]/[app]/doctype/[name]/`. If those files don't exist, you get the error.

## Diagnostic Commands

Enter the Frappe console:

```bash
bench --site yoursite.local console
```

Check if a DocType exists and its custom flag:

```python
frappe.get_all('DocType', filters={'name': 'District'})
doc = frappe.get_doc('DocType', 'District')
print(doc.is_virtual, doc.custom, doc.module)
# Output: 0 0 YOUR-MODULE
```

List all DocTypes in your module:

```python
print(frappe.get_all('DocType',
    filters={'module': 'YOUR-MODULE'},
    fields=['name', 'custom']))
```

Check if controller files exist:

```bash
ls -la ~/frappe-bench/apps/your-app/your-app/doctype/
```

If the directory is empty or doesn't exist, that's your problem.

## Solution 1: Convert to Custom DocType (Quickest)

When you don't have the source code, flip `custom = 0` to `custom = 1`. This tells Frappe to use database-only definitions.

For a single DocType:

```bash
bench --site yoursite.local console
```

```python
frappe.db.set_value('DocType', 'District', 'custom', 1)
frappe.db.commit()
frappe.clear_cache()
```

For multiple DocTypes:

```python
doctypes = [
    'District',
    'Citizen',
    'License Application',
    'Officer Posting',
    'Document',
]
for dt in doctypes:
    frappe.db.set_value('DocType', dt, 'custom', 1)
frappe.db.commit()
frappe.clear_cache()
```

Restart and verify:

```bash
bench restart
# Access: http://yoursite.local/app/district
```

**Pros:** Works immediately, no source code needed.
**Cons:** Can't add Python controller logic or custom JavaScript.

## Solution 2: Generate Controller Files (Full Functionality)

If you have (or can create) a proper app structure:

Ensure the app directory exists:

```bash
mkdir -p ~/frappe-bench/apps/your-app/your-app/doctype/
touch ~/frappe-bench/apps/your-app/your-app/doctype/__init__.py
```

Force Frappe to generate controllers:

```bash
bench --site yoursite.local console
```

```python
frappe.reload_doc('your-app', 'doctype', 'District')
frappe.db.commit()
```

Or run migration to regenerate all:

```bash
bench --site your-site migrate
```

**Pros:** Full controller functionality with Python and JavaScript.
**Cons:** Requires proper app structure.

## Solution 3: Register Module in hooks.py

If the module doesn't appear in the sidebar:

Edit `hooks.py`:

```bash
nano ~/frappe-bench/apps/your-app/your-app/hooks.py
```

Add module registration:

```python
app_name = "your-app"
app_title = "Your App Title"

app_modules = [
    {
        "module_name": "YOUR-MODULE",
        "color": "blue",
        "icon": "octicon octicon-file-directory",
        "type": "module",
        "label": "YOUR-MODULE"
    }
]
```

Clear cache and restart:

```bash
bench --site your-site clear-cache
bench restart
```

Verify:

```python
print(frappe.get_hooks('app_modules'))
# Should show: [{'module_name': 'YOUR-MODULE', ...}]
```

## Complete Restore Workflow

### Before Restore

```bash
# Enable maintenance mode
bench --site your-site set-maintenance-mode on

# Disable scheduler
bench --site your-site disable-scheduler
```

### Inspect the Backup

```bash
gunzip -c backup.sql.gz > backup.sql

# Find installed apps
grep "INSERT INTO \`tabInstalled Application\` VALUES" backup.sql

# Find modules
grep "INSERT INTO \`tabModule Def\` VALUES" backup.sql | head -20

# Check Frappe version
grep -A 5 "begin frappe metadata" backup.sql
```

### Prepare the Bench

```bash
cd ~/frappe-bench

# Get apps from repositories
bench get-app erpnext --branch version-15
bench get-app https://github.com/your-org/your-app.git
```

For apps without repositories, create a minimal placeholder:

```bash
cd ~/frappe-bench/apps
mkdir -p your-app/your-app

cat > your-app/setup.py << 'EOF'
from setuptools import setup, find_packages
setup(name='your-app', version='0.0.1', packages=find_packages())
EOF

cat > your-app/your-app/__init__.py << 'EOF'
__version__ = '0.0.1'
app_name = "your-app"
app_title = "Your App"
EOF

cat > your-app/your-app/hooks.py << 'EOF'
app_name = "your-app"
app_title = "Your App"
app_modules = [
    {
        "module_name": "YOUR-MODULE",
        "color": "blue",
        "icon": "octicon octicon-file-directory",
        "type": "module",
        "label": "YOUR-MODULE"
    }
]
EOF
```

### Install Apps and Restore

```bash
# Install apps BEFORE restoring database
bench --site your-site install-app frappe
bench --site your-site install-app erpnext
bench --site your-site install-app your-app

# Restore database
bench --site your-site restore /path/to/backup.sql.gz
```

### Restore Files

```bash
cd ~/frappe-bench/sites/your-site

# Extract public files
tar -xf /path/to/backup-files.tar -C .

# Move to correct location
mv your-app.local/public/files/* public/files/
mv your-app.local/private/files/* private/files/

# Fix permissions
sudo chown -R frappe:frappe public/files/
sudo chown -R frappe:frappe private/files/

# Cleanup
rm -rf your-app.local/
```

### Post-Restore

```bash
bench --site your-site migrate
bench --site your-site clear-cache
bench --site your-site clear-website-cache
bench --site your-site scheduler enable
bench --site your-site set-maintenance-mode off
bench restart
```

### Verify

```bash
bench --site your-site console
```

```python
print(frappe.get_installed_apps())
print(frappe.db.count('Your DocType'))
```

## Troubleshooting

### "Module Not Found" after setting `custom=1`

Check if the module is registered in hooks.py:

```python
print(frappe.get_hooks('app_modules'))
# If empty, add to hooks.py
```

### URLs don't work

Frappe v15 uses a new URL format:
- Old: `/app/doctype/District`
- New: `/app/district`

### Permission denied during file restore

Extract to `/tmp` first, then copy:

```bash
cd /tmp
tar -xf /path/to/backup-files.tar
cp -r your-app.local/public/files/* ~/frappe-bench/sites/your-site/public/files/
```

## Summary

| Situation | Solution |
|-----------|----------|
| Quick fix, no source code | Set `custom=1` |
| Have source repository | Generate controllers with `bench migrate` |
| Module not in sidebar | Register in `hooks.py` |
| Need custom business logic | Full controller setup |

The database always contains the truth about your schema. The app folder provides the behavior layer. For data-only needs, the database is sufficient.

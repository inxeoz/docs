# Fixing Database DocTypes in Frappé After Restore

## Introduction

When restoring a Frappé site from a database backup, you may encounter a frustrating error: **"Module Not Found"** or **"The resource you are looking for is not available"** when trying to access custom DocTypes. This commonly happens when:

- You're restoring from a backup without the original app source code
- The app was created as a "placeholder" without proper controller files
- Database schema exists but Frappé expects controller files that don't exist

This guide walks through diagnosing and fixing these issues using a real-world scenario from an ALIS (Arms Licence Information System) restoration.

---

## Common Symptoms

When accessing a DocType URL like `/app/doctype/District` or `/app/district`:

```
Not found
Module ALIS-APP not found
The resource you are looking for is not available
```

Or you might see:
- **HTTP 404 errors** for DocType pages
- **Empty module lists** in the sidebar
- **Broken links** from restored dashboards

---

## Pre-Restore: SQL Database Restoration Workflow

Before restoring a Frappé database, follow this complete workflow to ensure a smooth restoration process.

### Phase 1: Pre-Restore Preparation

#### 1.1 Enable Maintenance Mode

Prevent users from accessing the site during restore:

```bash
bench --site [your-site] set-maintenance-mode on
```

#### 1.2 Disable Scheduler

Stop background jobs to prevent conflicts:

```bash
bench --site [your-site] disable-scheduler
```

#### 1.3 Check Current State

```bash
# Verify maintenance mode
bench --site [your-site] console
print(frappe.conf.maintenance_mode)
# Should show: True

# Check scheduler status
print(frappe.conf.scheduler_enabled)
# Should show: 0 (Disabled)
```

### Phase 2: Inspect Backup for Required Apps

Before restoring, find out what apps you need from the SQL backup itself:

#### 2.1 Extract App Information from SQL Backup

```bash
# Decompress backup
gunzip -c backup-file.sql.gz > backup.sql

# Find all installed applications
grep "INSERT INTO \`tabInstalled Application\` VALUES" backup.sql
```

**Example output:**
```sql
INSERT INTO `tabInstalled Application` VALUES
('id1','2025-12-29','frappe','15.91.3','version-15',...),
('id2','2025-12-29','erpnext','15.91.3','version-15',...),
('id3','2025-12-29','alisapp','0.0.1','develop',...);
```

**Apps identified:** `frappe`, `erpnext`, `alisapp`

#### 2.2 Check for Custom Modules

```bash
# Find all modules and their apps
grep "INSERT INTO \`tabModule Def\` VALUES" backup.sql | head -20
```

**Example output:**
```sql
('Accounts','erpnext',...),
('ALIS-APP','alisapp',...),
('CRM','erpnext',...)
```

**Modules by app:**
- `erpnext`: Accounts, CRM, Stock, etc.
- `alisapp`: ALIS-APP (custom module)

#### 2.3 Check Frappé Version Compatibility

```bash
# Find version from backup metadata
grep -A 5 "begin frappe metadata" backup.sql
```

**Example:**
```
-- [frappe]
-- version = 15.91.3
-- branch = version-15
```

**Action:** Ensure your bench has matching or compatible versions.

### Phase 3: Prepare Bench Environment

#### 3.1 Install Missing Apps

**For apps with repositories:**
```bash
cd ~/frappe-bench

# Get apps from repositories
bench get-app erpnext --branch version-15
bench get-app https://github.com/your-org/alisapp.git
```

**For apps without repositories (placeholder approach):**

If you don't have the source code, create a minimal placeholder:

```bash
cd ~/frappe-bench/apps

# Create minimal app structure
mkdir -p alisapp/alisapp
cat > alisapp/setup.py << 'EOF'
from setuptools import setup, find_packages
setup(name='alisapp', version='0.0.1', packages=find_packages())
EOF

cat > alisapp/alisapp/__init__.py << 'EOF'
__version__ = '0.0.1'
app_name = "alisapp"
app_title = "ALIS-APP"
app_publisher = "Administrator"
app_description = "Arms Licence System"
app_email = "admin@local"
app_license = "MIT"
EOF

# Create hooks.py with module registration
cat > alisapp/alisapp/hooks.py << 'EOF'
app_name = "alisapp"
app_title = "ALIS-APP"

app_modules = [
    {
        "module_name": "ALIS-APP",
        "color": "blue",
        "icon": "octicon octicon-file-directory",
        "type": "module",
        "label": "ALIS-APP"
    }
]
EOF

# Touch required files
touch alisapp/alisapp/modules.txt
touch alisapp/alisapp/patches.txt
mkdir -p alisapp/alisapp/config
mkdir -p alisapp/alisapp/public
mkdir -p alisapp/alisapp/templates
mkdir -p alisapp/alisapp/www
```

#### 3.2 Verify Apps Are Available

```bash
cd ~/frappe-bench

# List available apps
ls apps/

# Check app versions
bench version
```

### Phase 4: Restore SQL Database

#### 4.1 Create New Site (If Needed)

```bash
# Create new site (skip if restoring to existing)
bench new-site [new-site-name] --mariadb-root-password [root-pass]
```

#### 4.2 Install Required Apps to Site

**Important:** Install apps BEFORE restoring database

```bash
bench --site [your-site] install-app frappe
bench --site [your-site] install-app erpnext
bench --site [your-site] install-app alisapp
```

**Verify installations:**
```bash
bench --site [your-site] list-apps
```

#### 4.3 Restore Database

```bash
# Standard bench restore (handles everything)
bench --site [your-site] restore /path/to/backup.sql.gz

# Or with explicit database file
bench --site [your-site] restore /path/to/backup.sql
```

**What bench restore does:**
1. ✅ Drops existing database tables
2. ✅ Creates new tables from backup
3. ✅ Imports all data
4. ✅ Updates site_config.json
5. ✅ Runs initial migration

#### 4.4 Alternative: Manual SQL Import

If bench restore fails or for advanced scenarios:

```bash
# Decompress first
gunzip -c backup.sql.gz > backup.sql

# Get current database credentials
cat sites/[your-site]/site_config.json

# Import manually (use with caution)
mysql -h [host] -u [db_user] -p[db_password] [db_name] < backup.sql
```

### Phase 5: Post-Restore Configuration

#### 5.1 Restore Site Config

The backup includes `site_config_backup.json`:

```bash
# Copy encryption key and settings
cp backup-site_config_backup.json sites/[your-site]/site_config.json

# Or merge selectively (keep current DB credentials)
cat sites/[your-site]/site_config_backup.json | jq '.encryption_key'
# Then manually add to current site_config.json
```

#### 5.2 Restore Public and Private Files

```bash
cd /path/to/backup/files

# Extract public files
tar -xzf backup-files.tar -C ~/frappe-bench/sites/[your-site]/

# Ensure proper ownership
sudo chown -R [user]:[group] ~/frappe-bench/sites/[your-site]/public/files/
sudo chown -R [user]:[group] ~/frappe-bench/sites/[your-site]/private/files/
```

### Phase 6: Migration and Cleanup

#### 6.1 Run Migration

```bash
# Full migration - synchronizes all DocTypes, fields, and updates
bench --site [your-site] migrate
```

**What migration does:**
- ✅ Synchronizes database schema with app definitions
- ✅ Applies pending patches
- ✅ Rebuilds search index
- ✅ Updates dashboards
- ✅ Generates controller files (if apps have them)

#### 6.2 Clear All Caches

```bash
# Clear all caches
bench --site [your-site] clear-cache
bench --site [your-site] clear-website-cache
bench --site [your-site] clear-web-cache
```

#### 6.3 Re-enable Scheduler

```bash
bench --site [your-site] scheduler enable
```

#### 6.4 Disable Maintenance Mode

```bash
bench --site [your-site] maintenance-mode off
```

### Phase 7: Verification

#### 7.1 Check Apps and Data

```bash
bench --site [your-site] console

# Verify apps
print(frappe.get_installed_apps())
# Should show: ['frappe', 'erpnext', 'alisapp']

# Check DocTypes
print(frappe.get_all('DocType', limit=10))

# Verify record counts
print(frappe.db.count('User'))
print(frappe.db.count('Arms Licence Application'))
```

#### 7.2 Test Login

- Access: `http://[your-site]:8000`
- Login with original credentials
- If passwords don't work: `bench --site [your-site] set-admin-password newpass`

#### 7.3 Restart Services

```bash
bench restart
```

---

## Complete Pre-Restore Checklist

### Before You Start:
- [ ] **Backup current site** (if not empty)
- [ ] **Enable maintenance mode**
- [ ] **Disable scheduler**
- [ ] **Inspect backup for required apps** (using SQL grep commands)
- [ ] **Check Frappé version compatibility**

### During Restore:
- [ ] **Create site** (if new)
- [ ] **Install all required apps** (from backup analysis)
- [ ] **Create placeholder apps** (if source code missing)
- [ ] **Restore database** (using bench restore or manual import)
- [ ] **Restore site config** (encryption key from backup)
- [ ] **Restore files** (public and private)

### After Restore:
- [ ] **Run bench migrate**
- [ ] **Clear all caches**
- [ ] **Re-enable scheduler**
- [ ] **Disable maintenance mode**
- [ ] **Verify DocTypes are accessible**
- [ ] **Test login and functionality**
- [ ] **Restart bench**

---

## Understanding the Root Cause

### The Frappé Architecture

Frappé DocTypes can exist in two states:

| Flag | Description | Requirements |
|------|-------------|--------------|
| `custom = 0` | **Standard DocType** | Requires controller files (`.py`, `.js`, `.json`) in the app folder |
| `custom = 1` | **Custom DocType** | Uses database schema only; no controller files needed |

### What Happens During Restore

1. ✅ **Database tables** are restored with all schema definitions (`tabDocType`, `tabDocField`)
2. ❌ **App folder** may be missing or is a placeholder without controller files
3. ❌ Frappé sees `custom = 0` and looks for files at `apps/[app]/[app]/doctype/[name]/`
4. ❌ **Error:** Files don't exist → "Module not found"

---

## Diagnostic Commands

### Check if DocType Exists

```bash
bench --site [your-site] console
```

```python
# Check if DocType exists in database
frappe.get_all('DocType', filters={'name': 'District'})

# Check if it's marked as custom
doc = frappe.get_doc('DocType', 'District')
print(doc.is_virtual, doc.custom, doc.module)
# Output: 0 0 ALIS-APP
# is_virtual=0, custom=0, module=ALIS-APP
```

### List All DocTypes in a Module

```python
print(frappe.get_all('DocType', 
    filters={'module': 'ALIS-APP'}, 
    fields=['name', 'custom']))
```

**Example output:**
```python
[
    {'name': 'District', 'custom': 0},
    {'name': 'Arms Licence Application', 'custom': 0},
    # ... 9 more DocTypes
]
```

### Check Controller Files

```bash
ls -la ~/frappe-bench/apps/[your-app]/[your-app]/doctype/
```

If you see:
```
Directory doesn't exist
```

Or the directory is empty, that's your problem.

### Check App Module Registration

```python
print(frappe.get_hooks('app_modules'))
# Empty list [] means module not registered
```

Should show:
```python
[{'module_name': 'ALIS-APP', 'color': 'blue', 'icon': 'octicon octicon-file-directory', 'type': 'module', 'label': 'ALIS-APP'}]
```

---

## Solutions

### Solution 1: Convert to Custom DocType (Quickest)

**When to use:** You don't have the original app source code and need a quick fix.

**What it does:** Changes `custom = 0` to `custom = 1`, telling Frappé to use database-only definitions.

```bash
bench --site [your-site] console
```

For a single DocType:
```python
frappe.db.set_value('DocType', 'District', 'custom', 1)
frappe.db.commit()
frappe.clear_cache()
```

For multiple DocTypes:
```python
doctypes = [
    'District',
    'Arms Licence Application', 
    'ALIS Citizen',
    'Weapon Type Master',
    'Tehsil',
    'Police Station',
    'Purpose Master',
    'Officer Posting',
    'ALIS Document',
    'Licence Conditions Master',
    'ALIS Checklist',
    'ALIS Timeline'
]
for dt in doctypes:
    frappe.db.set_value('DocType', dt, 'custom', 1)
frappe.db.commit()
frappe.clear_cache()
```

**Verification:**
```bash
bench restart
# Then access: http://[your-site]/app/district
```

**Pros:**
- ✅ Works immediately
- ✅ No controller files needed
- ✅ Perfect for data-only restores

**Cons:**
- ❌ Can't add Python controller logic (server-side scripts)
- ❌ No custom JavaScript for the DocType
- ❌ Limited to standard Frappé functionality

---

### Solution 2: Generate Controller Files (Full Functionality)

**When to use:** You have (or can create) a proper app structure and need full controller functionality.

**Step 1:** Ensure proper app structure exists:

```bash
mkdir -p ~/frappe-bench/apps/[your-app]/[your-app]/doctype/
touch ~/frappe-bench/apps/[your-app]/[your-app]/doctype/__init__.py
```

**Step 2:** Force Frappé to generate controllers:

```bash
bench --site [your-site] console
```

```python
# Generate controller for specific DocType
frappe.reload_doc('[your-app]', 'doctype', 'District')
frappe.db.commit()

# Or regenerate all
# Run: bench --site [your-site] migrate
```

**Pros:**
- ✅ Full controller functionality
- ✅ Can add Python business logic
- ✅ Can add custom JavaScript

**Cons:**
- ❌ Requires proper app structure
- ❌ May fail with placeholder apps
- ❌ More complex setup

---

### Solution 3: Register Module in hooks.py

**When to use:** The module doesn't appear in the sidebar or Desk menu.

**Step 1:** Edit `hooks.py`:

```bash
nano ~/frappe-bench/apps/[your-app]/[your-app]/hooks.py
```

**Step 2:** Add module registration:

```python
app_name = "[your-app]"
app_title = "[Your App Title]"
app_publisher = "Your Name"
app_description = "Description"
app_email = "email@example.com"
app_license = "MIT"

# Register the module
app_modules = [
    {
        "module_name": "ALIS-APP",
        "color": "blue",
        "icon": "octicon octicon-file-directory", 
        "type": "module",
        "label": "ALIS-APP"
    }
]
```

**Step 3:** Clear cache and restart:

```bash
bench --site [your-site] clear-cache
bench restart
```

**Verification:**

```python
print(frappe.get_hooks('app_modules'))
# Should show: [{'module_name': 'ALIS-APP', ...}]
```

---

## Real-World Example: Complete Walkthrough

### Scenario

- **Source:** Backup from `alis_local` site (Frappé v15.91.3)
- **Destination:** New site `alis.inxeoz.com` with placeholder `alisapp`
- **Problem:** "Module ALIS-APP not found" when accessing any ALIS DocType
- **DocTypes affected:** 12 DocTypes (District, Arms Licence Application, ALIS Citizen, etc.)

### The Problem

```bash
# After database restore
bench --site alis.inxeoz.com console

print(frappe.get_all('DocType', filters={'module': 'ALIS-APP'}, fields=['name', 'custom']))
# Shows: all have custom=0 (standard DocTypes needing controllers)

# Check if controllers exist
ls apps/alisapp/alisapp/doctype/
# Output: Directory doesn't exist
```

### The Solution

```bash
# Set all to custom=1
bench --site alis.inxeoz.com console

doctypes = ['District', 'Arms Licence Application', 'ALIS Citizen',
            'Weapon Type Master', 'Tehsil', 'Police Station',
            'Purpose Master', 'Officer Posting', 'ALIS Document',
            'Licence Conditions Master', 'ALIS Checklist', 'ALIS Timeline']
for dt in doctypes:
    frappe.db.set_value('DocType', dt, 'custom', 1)

frappe.db.commit()
frappe.clear_cache()
```

### Verification

```bash
# Restart
bench restart

# Test URL
# http://alis.inxeoz.com/app/district - Works!
# http://alis.inxeoz.com/app/arms-licence-application - Works!
```

---

## Quick Reference: Essential Commands

| Purpose | Command |
|---------|---------|
| **Check DocType status** | `frappe.get_doc('DocType', 'Name').custom` |
| **List module DocTypes** | `frappe.get_all('DocType', filters={'module': 'Module-Name'})` |
| **Convert to custom** | `frappe.db.set_value('DocType', 'Name', 'custom', 1)` |
| **Check app modules** | `frappe.get_hooks('app_modules')` |
| **Clear cache** | `frappe.clear_cache()` or `bench --site [site] clear-cache` |
| **Restart bench** | `bench restart` |
| **Enter console** | `bench --site [site] console` |
| **List apps** | `bench --site [site] list-apps` |
| **Migrate site** | `bench --site [site] migrate` |
| **Check file structure** | `ls apps/[app]/[app]/doctype/` |
| **Enable maintenance mode** | `bench --site [site] maintenance-mode on` |
| **Disable scheduler** | `bench --site [site] scheduler disable` |
| **Enable scheduler** | `bench --site [site] scheduler enable` |
| **Find apps in SQL backup** | `grep "INSERT INTO \`tabInstalled Application\` VALUES" backup.sql` |
| **Find modules in SQL backup** | `grep "INSERT INTO \`tabModule Def\` VALUES" backup.sql` |

---

## Best Practices & Warnings

### Always Backup First

Before making `custom` flag changes:

```bash
# Create a database backup
mysqldump -h [host] -u [user] -p [database] > backup_before_fix.sql
```

### Custom DocType Limitations

When `custom = 1`:
- ❌ Cannot add Python controller methods
- ❌ Cannot add custom JavaScript
- ❌ No custom validation logic
- ❌ Limited to Frappé's built-in functionality

### When to Use Each Solution

| Situation | Recommended Solution |
|-----------|---------------------|
| Quick fix, no source code | **Solution 1:** Set `custom=1` |
| Have source repository | **Solution 2:** Generate controllers |
| Module not in sidebar | **Solution 3:** Register in hooks.py |
| Need custom business logic | **Solution 2:** Full controller setup |
| Database-only restore | **Solution 1:** Set `custom=1` |

### For Production Apps

If you have the original source code:

1. Clone the repository: `bench get-app [repo-url]`
2. Install the app: `bench --site [site] install-app [app]`
3. Restore database: `bench --site [site] restore backup.sql.gz`
4. Run migration: `bench --site [site] migrate`

This maintains full functionality with controllers.

---

## Troubleshooting Common Issues

### Issue: Still Getting "Module Not Found" After Setting custom=1

**Check:** Is the module registered in hooks.py?

```python
print(frappe.get_hooks('app_modules'))
# If empty, add to hooks.py
```

### Issue: Permission Denied

**Fix:** Ensure proper file permissions

```bash
sudo chown -R frappe:frappe ~/frappe-bench/
bench --site [site] clear-cache
```

### Issue: Changes Not Reflecting

**Fix:** Clear all caches

```bash
bench --site [site] clear-cache
bench --site [site] clear-website-cache
bench --site [site] clear-web-cache
bench restart
```

### Issue: URLs Still Don't Work

**Check:** Frappé v15 uses new URL format:
- ❌ Old: `/app/doctype/District`
- ✅ New: `/app/district`

### Issue: DocTypes Missing After Restore

**Check:** Were they in the backup?

```sql
-- Check if DocType definitions exist in database
SELECT name, module, custom FROM tabDocType WHERE module = 'YOUR-MODULE';
```

---

## Conclusion

Restoring a Frappé site without the original app source code is possible by leveraging the database schema definitions. The key is understanding the difference between `custom = 0` (requires controllers) and `custom = 1` (database-only).

For quick data access without custom logic, setting DocTypes to `custom = 1` provides an immediate solution. For full functionality with custom business logic, you'll need the original source code or must recreate the controller files.

Remember: The database always contains the truth about your schema. The app folder provides the behavior layer. For data-only needs, the database is sufficient.

---

## Related Resources

- [Frappé Framework Documentation](https://frappeframework.com/docs)
- [DocType Documentation](https://frappeframework.com/docs/user/en/basics/doctypes)
- [Bench CLI Reference](https://frappeframework.com/docs/user/en/bench)
- [Restoring Sites in Frappé](https://frappeframework.com/docs/user/en/basics/site-restore)

---

*Written based on real-world experience restoring an ALIS (Arms Licence Information System) Frappé v15 site without original source code.*

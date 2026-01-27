

# How to Export Everything Created via UI in Frappe / ERPNext

### (Complete Guide: DocTypes, Scripts, Workflow, Roles, Dashboards & Data)

In real-world Frappe / ERPNext projects, most things are **initially created via the UI**:

* DocTypes
* Custom Fields
* Client / Server Scripts
* Workflows
* Roles & Permissions
* Dashboards & Charts
* Master Data
* Business Records

At some point, you **must export all of this** so that it can be:

* Version controlled (Git)
* Installed on another site
* Migrated to staging / production
* Backed up safely

This article explains **exactly how to export EVERYTHING created via the UI**, the **correct and safe Frappe way**.

---

## 1. How Frappe stores UI-created things

Frappe stores data in **three layers**:

### 1️⃣ Code (filesystem)

* DocTypes
* Reports
* Pages
* Web Forms

📌 These are exported as **files**
📌 Only if they belong to your app module

---

### 2️⃣ Configuration records (database)

* Custom Field
* Property Setter
* Client Script
* Server Script
* Workflow
* Role
* Dashboard
* Notification

📌 Stored in DB
📌 Exported using **fixtures**

---

### 3️⃣ Business / master data (database rows)

* Master data (District, Type, Category, etc.)
* Business documents (Applications, Citizens, etc.)

📌 Stored in DB
📌 Exported using **fixtures (with filters)**

---

## 2. Prerequisite: Module ownership (MANDATORY)

Before exporting anything, ensure:

* **Module = YOUR_APP** (e.g. `ALIS-APP`)
* For **every DocType, Script, Workflow, Dashboard**

If module is wrong:

* Export will fail
* Or data will export to the wrong app

---

## 3. CRITICAL STEP: Converting UI DocTypes into app DocTypes (`custom = 0`)

### ❓ Why this is needed

When a DocType is created from the UI, Frappe marks it as:

```text
custom = 1
```

This means:

* Frappe treats it as a **Custom DocType**
* It may not behave like a proper app-owned DocType
* It can cause issues during export, install, or migration

For a **real app**, DocTypes must be treated as **standard (app) DocTypes**.

That is done by setting:

```text
custom = 0
```

---

### ✅ When you SHOULD set `custom = 0`

✔ You created the DocType via UI
✔ The DocType belongs permanently to your app
✔ You want it versioned, exported, and installed elsewhere

This is the **correct approach for production apps**.

---

### ❌ When you should NOT do this

❌ DocTypes created only for a single site
❌ Temporary or experimental DocTypes
❌ Customer-specific customizations

Those should remain `custom = 1`.

---

### 🔧 How to convert UI-created DocTypes to app DocTypes

Run this **once** in bench console:

```python
doctypes = frappe.get_all(
    "DocType",
    filters={"module": "ALIS-APP"},
    pluck="name"
)

for d in doctypes:
    dt = frappe.get_doc("DocType", d)
    dt.custom = 0
    dt.save()
```

Then run:

```bash
bench --site yoursite migrate
```

✅ Your DocTypes are now **first-class app DocTypes**
✅ They will export cleanly
✅ They will install correctly on other sites

---

## 4. Verify DocTypes owned by your module

This becomes your **source of truth**:

```python
frappe.get_all(
    "DocType",
    filters={"module": "ALIS-APP"},
    pluck="name"
)
```

Use this list for:

* Workflow export
* Permission export
* Data export filters

---

## 5. What are Fixtures?

**Fixtures** are Frappe’s official way to export **database records** into JSON files.

They are defined in:

```
apps/your_app/your_app/hooks.py
```

Fixtures are automatically:

* Exported using `export-fixtures`
* Imported during `migrate`

---

## 6. Full fixtures configuration (UI → Git)

Below is a **real-world fixtures setup** that exports *everything created via UI*.

```python
fixtures = [

    # -----------------------------
    # CUSTOMIZATION
    # -----------------------------
    {
        "dt": "Custom Field",
        "filters": [["module", "=", "ALIS-APP"]],
    },
    {
        "dt": "Property Setter",
        "filters": [["module", "=", "ALIS-APP"]],
    },

    # -----------------------------
    # SCRIPTS
    # -----------------------------
    {
        "dt": "Client Script",
        "filters": [["module", "=", "ALIS-APP"]],
    },
    {
        "dt": "Server Script",
        "filters": [["module", "=", "ALIS-APP"]],
    },

    # -----------------------------
    # WORKFLOW
    # (Workflow has NO module field)
    # -----------------------------
    {
        "dt": "Workflow",
        "filters": [["document_type", "in", [
            "ALIS Citizen",
            "Arms Licence Application",
        ]]],
    },
    {"dt": "Workflow State"},
    {"dt": "Workflow Action Master"},

    # -----------------------------
    # ROLES & PERMISSIONS
    # -----------------------------
    {
        "dt": "Role",
        "filters": [["name", "like", "ALIS%"]],
    },
    {
        "dt": "Custom DocPerm",
        "filters": [["parent", "in", [
            "ALIS Citizen",
            "Arms Licence Application",
        ]]],
    },

    # -----------------------------
    # DASHBOARDS & UI
    # -----------------------------
    {
        "dt": "Dashboard",
        "filters": [["module", "=", "ALIS-APP"]],
    },
    {
        "dt": "Dashboard Chart",
        "filters": [["module", "=", "ALIS-APP"]],
    },
    {
        "dt": "Dashboard Chart Source",
        "filters": [["module", "=", "ALIS-APP"]],
    },
    {
        "dt": "Number Card",
        "filters": [["module", "=", "ALIS-APP"]],
    },

    # -----------------------------
    # NOTIFICATIONS
    # -----------------------------
    {
        "dt": "Notification",
        "filters": [["module", "=", "ALIS-APP"]],
    },

    # -----------------------------
    # MASTER DATA
    # -----------------------------
    {"dt": "District"},
    {"dt": "Purpose Master"},

    # -----------------------------
    # BUSINESS DATA (FILTERED)
    # -----------------------------
    {
        "dt": "ALIS Citizen",
        "filters": [["is_active", "=", 1]],
    },
    {
        "dt": "Arms Licence Application",
        "filters": [["docstatus", "<", 2]],
    },
]
```

---

## 7. IMPORTANT: Validate fields before using filters

Fixtures execute **raw SQL**.

Always verify fields first:

```python
meta = frappe.get_meta("ALIS Citizen")
[f.fieldname for f in meta.fields]
```

Or:

```python
meta.has_field("is_active")
```

If a field doesn’t exist → **export will crash**.

---

## 8. Export everything

```bash
bench --site yoursite export-fixtures
```

Fixtures are written to:

```
apps/your_app/your_app/fixtures/
```

---

## 9. Commit to Git (this is your backup)

```bash
git add .
git commit -m "Export all UI-created config and data"
```

---

## 10. Restore on another site

```bash
bench --site targetsite install-app your_app
bench --site targetsite migrate
bench --site targetsite clear-cache
```

Everything created via UI is restored automatically.

---

## 11. Production warning (important)

Fixtures are **re-applied on every migrate**.

### Best practice:

* Fixtures → configuration + master data
* Patches → one-time business data

Never fixture accounting or ledger tables.

---

## Final takeaway

> **UI-created does NOT mean non-portable.**
> If done correctly, everything created via UI can be exported, versioned, and deployed cleanly.

The **missing piece most people forget** is converting UI DocTypes into **real app DocTypes** using:

```text
custom = 0
```

Once you do that, the rest of the system works exactly as designed.

---

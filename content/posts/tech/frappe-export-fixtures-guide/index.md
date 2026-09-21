---
title: "How to Version-Control Everything You Built in Frappe's UI"
date: 2026-07-26
draft: false
tags: ["frappe", "erpnext", "fixtures", "version-control", "export", "git"]
categories: ["Tech"]
viewMode: docs
showToc: true
---

In Frappe projects, most things are created via the UI: DocTypes, Custom Fields, Client Scripts, Server Scripts, Workflows, Roles, Dashboards, and Master Data. At some point you need to export all of this so it can be version-controlled, installed on another site, or migrated to production.

The missing piece most people forget is converting UI DocTypes into real app DocTypes using `custom = 0`. Once you do that, the rest of the system works exactly as designed.

## How Frappe Stores UI-Created Things

Frappe stores data in three layers:

### Layer 1: Code (filesystem)

DocTypes, Reports, Pages, Web Forms — exported as files, only if they belong to your app module.

### Layer 2: Configuration records (database)

Custom Fields, Property Setters, Client Scripts, Server Scripts, Workflows, Roles, Dashboards, Notifications — stored in DB, exported using **fixtures**.

### Layer 3: Business/master data (database rows)

Master data (Districts, Types, Categories), Business documents (Applications, Records) — stored in DB, exported using **fixtures with filters**.

## The Critical Step: Convert UI DocTypes to App DocTypes

When a DocType is created from the UI, Frappe marks it as `custom = 1`. For a real app, DocTypes must be `custom = 0`.

Run this once in bench console:

```bash
bench --site yoursite.local console
```

```python
doctypes = frappe.get_all(
    "DocType",
    filters={"module": "YOUR-MODULE"},
    pluck="name"
)

for d in doctypes:
    dt = frappe.get_doc("DocType", d)
    dt.custom = 0
    dt.save()
```

Then run:

```bash
bench --site yoursite.local migrate
```

Your DocTypes are now first-class app DocTypes — they will export cleanly and install correctly on other sites.

### When to set `custom = 0`

- You created the DocType via UI
- The DocType belongs permanently to your app
- You want it versioned, exported, and installed elsewhere

### When NOT to do this

- DocTypes created only for a single site
- Temporary or experimental DocTypes
- Customer-specific customizations

## Verify Module Ownership

This becomes your source of truth:

```python
frappe.get_all(
    "DocType",
    filters={"module": "YOUR-MODULE"},
    pluck="name"
)
```

Use this list for workflow export, permission export, and data export filters.

## What Are Fixtures?

Fixtures are Frappe's official way to export database records into JSON files. They are defined in `apps/your_app/your_app/hooks.py`.

Fixtures are automatically:
- Exported using `export-fixtures`
- Imported during `migrate`

## Full Fixtures Configuration

Here's a real-world fixtures setup that exports everything created via UI:

```python
fixtures = [

    # -----------------------------
    # CUSTOMIZATION
    # -----------------------------
    {
        "dt": "Custom Field",
        "filters": [["module", "=", "YOUR-MODULE"]],
    },
    {
        "dt": "Property Setter",
        "filters": [["module", "=", "YOUR-MODULE"]],
    },

    # -----------------------------
    # SCRIPTS
    # -----------------------------
    {
        "dt": "Client Script",
        "filters": [["module", "=", "YOUR-MODULE"]],
    },
    {
        "dt": "Server Script",
        "filters": [["module", "=", "YOUR-MODULE"]],
    },

    # -----------------------------
    # WORKFLOW
    # (Workflow has NO module field)
    # -----------------------------
    {
        "dt": "Workflow",
        "filters": [["document_type", "in", [
            "Citizen",
            "License Application",
        ]]],
    },
    {"dt": "Workflow State"},
    {"dt": "Workflow Action Master"},

    # -----------------------------
    # ROLES & PERMISSIONS
    # -----------------------------
    {
        "dt": "Role",
        "filters": [["name", "like", "YOUR-MODULE%"]],
    },
    {
        "dt": "Custom DocPerm",
        "filters": [["parent", "in", [
            "Citizen",
            "License Application",
        ]]],
    },

    # -----------------------------
    # DASHBOARDS & UI
    # -----------------------------
    {
        "dt": "Dashboard",
        "filters": [["module", "=", "YOUR-MODULE"]],
    },
    {
        "dt": "Dashboard Chart",
        "filters": [["module", "=", "YOUR-MODULE"]],
    },
    {
        "dt": "Number Card",
        "filters": [["module", "=", "YOUR-MODULE"]],
    },

    # -----------------------------
    # NOTIFICATIONS
    # -----------------------------
    {
        "dt": "Notification",
        "filters": [["module", "=", "YOUR-MODULE"]],
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
        "dt": "Citizen",
        "filters": [["is_active", "=", 1]],
    },
    {
        "dt": "License Application",
        "filters": [["docstatus", "<", 2]],
    },
]
```

## Validate Fields Before Using Filters

Fixtures execute raw SQL. Always verify fields first:

```python
meta = frappe.get_meta("Citizen")
[f.fieldname for f in meta.fields]
```

Or:

```python
meta.has_field("is_active")
```

If a field doesn't exist, the export will crash.

## Export Everything

```bash
bench --site yoursite.local export-fixtures
```

Fixtures are written to:

```
apps/your_app/your_app/fixtures/
```

## Commit to Git

```bash
git add .
git commit -m "Export all UI-created config and data"
```

## Restore on Another Site

```bash
bench --site targetsite install-app your_app
bench --site targetsite migrate
bench --site targetsite clear-cache
```

Everything created via UI is restored automatically.

## Production Warning

Fixtures are re-applied on every `migrate`.

**Best practice:**
- Fixtures for configuration + master data
- Patches for one-time business data changes

Never fixture accounting or ledger tables.

## Summary

| Layer | What | Export Method |
|-------|------|---------------|
| Code | DocTypes, Reports, Pages | Files in app directory |
| Config | Custom Fields, Scripts, Workflows | Fixtures in `hooks.py` |
| Data | Master data, Business records | Fixtures with filters |

> UI-created does NOT mean non-portable. If done correctly, everything created via UI can be exported, versioned, and deployed cleanly.

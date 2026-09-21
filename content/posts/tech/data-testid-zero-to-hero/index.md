---
title: "data-testid — From Zero to Hero"
date: 2026-05-21
draft: false
tags: ["testing", "playwright", "eslint", "e2e"]
categories: ["Tech"]
viewMode: docs
---

A complete guide to mandatory `data-testid` enforcement, duplicate detection, auto-generation, and E2E workflow — with every command you need.

---

## 1. What is `data-testid` and why do you need it?

`data-testid` is an HTML attribute that decouples your tests from CSS classes, DOM structure, and text content. Instead of brittle selectors like `.btn-primary > span:first-child`, you write:

```js
page.locator('[data-testid="btn:submit-request"]').click();
```

Your tests survive refactors. Your CSS changes don't break your CI.

**Rule of thumb:** every visible UI element — every `<button>`, `<input>`, `<select>`, `<div>`, modal, table, tab, card — gets a `data-testid`. No exceptions.

---

## 2. Conventions

Format: `<scope>:<type>-<description>` — lowercase kebab-case.

| Scope | Element | Example |
|---|---|---|
| `btn` | Button | `btn:submit-request` |
| `input` | Text input | `input:username` |
| `select` | Dropdown | `select:status-filter` |
| `div` | Container | `div:modal-body` |
| `modal` | Modal | `modal:case-diary` |
| `table` | Table | `table:case-list` |
| `row` | Table row | `row:case-${id}` |
| `tab` | Tab | `tab:case-info` |
| `link` | Anchor | `link:view-pdf-${i}` |
| `card` | Card | `card:compliance-pending` |
| `section` | Section | `section:officer-details` |
| `badge` | Status badge | `badge:ga-allowed` |
| `icon` | Icon button | `icon:search` |
| `pagination` | Pagination | `pagination:next` |
| `nav-group` | Sidebar group | `nav-group:cases-menu` |

Dynamic IDs: `btn:view-case-${case.id}`.

Human-readable — not `div-btn`, but `btn:submit-request`.

---

## 3. Setup — ESLint

### 3a. Enforce that every JSX element **has** a `data-testid`

Use `eslint-plugin-react-require-testid`:

```bash
bun add -d eslint-plugin-react-require-testid
bun add -d eslint  # if not already installed
```

Configure `frontend/eslint.config.js`:

```js
const reactRequireTestId = require("eslint-plugin-react-require-testid");

module.exports = [
  {
    files: ["**/*.{js,jsx,ts,tsx}"],
    languageOptions: {
      parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module",
        ecmaFeatures: { jsx: true },
      },
    },
    plugins: {
      "react-require-testid": reactRequireTestId,
    },
    rules: {
      "react-require-testid/testid-missing": "warn",
    },
  },
];
```

Run it:

```bash
bunx eslint src
```

Every missing `data-testid` is reported. Fix them one by one.

### 3b. Catch duplicate `data-testid` values

Deduplication via a custom ESLint rule at `frontend/eslint-rules/no-duplicate-data-testid.js`:

```js
// eslint-rules/no-duplicate-data-testid.js
module.exports = {
  meta: {
    type: "problem",
    docs: { description: "Disallow duplicate data-testid values within the same scope" },
    messages: {
      duplicate: 'Duplicate data-testid "{{testId}}" found.',
    },
  },
  create(context) {
    const testIds = new Map();
    return {
      JSXAttribute(node) {
        if (
          node.name?.type === "JSXIdentifier" &&
          node.name.name === "data-testid" &&
          node.value?.type === "Literal" &&
          typeof node.value.value === "string"
        ) {
          if (testIds.has(node.value.value)) {
            context.report({ node, messageId: "duplicate", data: { testId: node.value.value } });
          } else {
            testIds.set(node.value.value, node);
          }
        }
      },
    };
  },
};
```

Register it in `eslint.config.js`:

```js
const noDuplicateDataTestId = require("./eslint-rules/no-duplicate-data-testid");

// inside module.exports:
{
  plugins: {
    "custom": { rules: { "no-duplicate-data-testid": noDuplicateDataTestId } },
  },
  rules: {
    "custom/no-duplicate-data-testid": "error",
  },
}
```

```bash
bunx eslint src
```

This is `"error"` — duplicate `data-testid` values **fail the build**.

---

## 4. Auto-generate missing `data-testid` values

Manually adding `data-testid` to hundreds of elements is tedious. Use the Babel-based codemod at `frontend/scripts/add-data-testid.js`.

The script:

1. Walks every `.js` and `.jsx` file under `src/`
2. For every JSX element **without** a `data-testid`, injects a random one
3. Preserves existing lines

Run it:

```bash
bun run add-data-testid
```

This calls `node scripts/add-data-testid.js`.

**After running:**
- Run `bunx eslint src` to find elements that still need human-readable names.
- The random IDs (`"a1b2c3"`) are placeholders — rename them to follow the `<scope>:<type>-<description>` convention.
- Re-run `bunx eslint src` to confirm zero warnings and zero duplicates.

---

## 5. Browser Extension — UI Path Copy

A companion browser extension lives at `frontend/e2e/cmts-navigator/`. It lets you right-click any element and copy its `data-testid` navigation path.

### Install

**Chrome:** `chrome://extensions` → Developer mode → Load unpacked → select `frontend/e2e/cmts-navigator/`.

**Firefox:** `about:debugging` → This Firefox → Load Temporary Add-on → `frontend/e2e/cmts-navigator/firefox/manifest.json`.

### Usage

Right-click any element → "Copy Navigation Path" → paste into your Playwright test.

Copies a `>`-delimited path: `div:form-actions > btn:submit-request`. Elements without `data-testid` fall back to `tag[index]`: `div[1] > div[2] > form[1] > btn:sign-in`.

---

## 6. Using `data-testid` in Playwright

```js
const { chromium } = require("playwright");

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto("http://localhost:5175");

  // Fill an input
  await page.locator('[data-testid="input:username"]').fill("admin");

  // Click a button
  await page.locator('[data-testid="btn:sign-in"]').click();

  // Wait for a modal
  await page.locator('[data-testid="modal:case-diary"]').waitFor();

  // Click a dynamic row
  await page.locator('[data-testid="row:case-42"]').click();

  // Verify a badge exists
  await expect(page.locator('[data-testid="badge:status-pending"]')).toBeVisible();

  await browser.close();
})();
```

Run it:

```bash
node frontend/e2e/your-test.spec.js
```

No screenshot unless asked. No brittle selectors. Your tests survive CSS rewrites.

---

## 7. Commands Cheat Sheet

```bash
# === ANALYSIS ===

# Find every element that still has a placeholder random testid
bunx eslint src | grep "testid-missing"

# Check for duplicates (returns non-zero if any found)
bunx eslint src

# Count how many unique data-testid values exist in the codebase
rg -o 'data-testid="([^"]+)"' src/ --no-filename | sort -u | wc -l

# Find all data-testid values sorted (spot duplicates yourself)
rg -o 'data-testid="([^"]+)"' src/ --no-filename | sort

# === AUTO-GENERATE ===

# Add random data-testid to every JSX element that misses one
bun run add-data-testid

# === VERIFY ===

# Full ESLint check — must pass before commit
bunx eslint src

# Run Playwright tests
node frontend/e2e/your-test.spec.js
```

---

## 8. CI Checklist

Before merge, every PR must pass:

```bash
bunx eslint src                  # 0 warnings, 0 errors
```

If you see `"Duplicate data-testid"` → fix the name.  
If you see `"testid-missing"` → add a human-readable `data-testid`.  
If the add-data-testid script created random IDs → rename them following the convention table above.

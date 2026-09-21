---
title: "SVG Icons In Font Using Fantasticon"
date: 2026-03-22
draft: false
tags: ["fonts", "svg"]
categories: ["Tech"]
viewMode: docs
lightbox: true
---

![SVG to icon font workflow](svg-font.webp)

### ✨ Why Use an Icon Font?

- **Single HTTP request** for all icons
- **Unicode character-based** referencing (like `a`, `b`, `c`)
- **Easier styling** via CSS
- **Cleaner markup** than embedding raw SVGs

### Step-by-Step: Create a Custom Icon Font with Fantasticon

### 1. Install Fantasticon

On Arch Linux (or any system with `npm`):

```bash
sudo pacman -S nodejs npm
sudo npm install -g fantasticon
```

### 2. Prepare Your SVG Icons

Create a folder like this:

```
project/
├── build
├── icons/
│   ├── home.svg
│   ├── user.svg
│   └── settings.svg
└── fantasticonrc.json
```

### 3. Configure `fantasticonrc.json`

This file tells Fantasticon how to build your font and map icons to characters:

```json
{
  "inputDir": "./icons",
  "outputDir": "./build",
  "fontTypes": ["ttf", "woff", "woff2"],
  "assetTypes": ["css", "json"],
  "name": "myiconfont",
  "codepoints": {
    "home": 97,
    "user": 98,
    "settings": 99
  }
}
```

> *Tip: 97 = ‘a’, 98 = ‘b’, 99 = ‘c’*

### 4. Generate the Font

Run Fantasticon in your project root:

```bash
fantasticon
```

This creates the font files and CSS:

```
build/
├── myiconfont.ttf
├── myiconfont.woff
├── myiconfont.css
```

### 🔧 Integrate Icon Font in Svelte

### 5. Move Font Files

Move the font files to SvelteKit’s `static` folder:

```
static/fonts/
├── myiconfont.woff
├── myiconfont.ttf
├── myiconfont.css
```

### 6. Import Font in Global Styles

In `src/app.css` (or wherever your global styles live):

*Note : ( In SvelteKit (and Vite), the* `*static*` *directory is served as the root at runtime, but during build/dev, CSS imports are resolved relative to the project root or the filesystem—not the dev server’s public path. ) use something like i.e*

**For local development**

```css
@import '../static/fonts/myiconfont.css';
```

**For runtime or production**

```css
@import '/fonts/myiconfont.css';
.icon {
  font-family: 'myiconfont';
  font-style: normal;
  font-weight: normal;
  display: inline-block;
  line-height: 1;
}
```

### 7. Use the Icon in Svelte

#### Basic HTML usage:

```html
<span class="icon">a</span> <!-- home icon -->
<span class="icon">b</span> <!-- user icon -->
<span class="icon">c</span> <!-- settings icon -->
```

### Bonus: Reusable Icon Component in Svelte

Create a wrapper component:

### `src/lib/Icon.svelte`

```html
<script>
  export let char = 'a'; // default icon
</script>
<span class="icon">{char}</span>
```

### Usage:

```html
<Icon char="a" /> <!-- home icon -->
<Icon char="b" /> <!-- user icon -->
```

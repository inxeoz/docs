---
title: "EPUB Reader"
date: 2026-08-20
draft: false
tags: ["epub", "books", "reader", "tools"]
categories: ["Tech"]
viewMode: docs
---

A small reader that lives entirely in this page. Pick an `.epub`, and it opens like a real book: turn pages with the buttons, the arrow keys, or a swipe on touch screens, jump around with the table of contents, and adjust the text size. Everything runs in your browser — the file is never uploaded anywhere.

<div id="epub-app" class="epub-app">

<style>
/* EPUB reader — styled with the site's own design tokens */
.epub-app { margin: 1.5rem 0; }
.epub-drop {
    display: block;
    padding: 2.75rem 1rem;
    text-align: center;
    border: 2px dashed var(--border-color);
    border-radius: 8px;
    color: var(--secondary-text);
    cursor: pointer;
    transition: border-color .15s ease, color .15s ease;
}
.epub-drop:hover, .epub-drop.dragover { border-color: var(--link-color); color: var(--link-color); }
.epub-drop .epub-drop-title { display: block; font-weight: var(--font-weight-semibold); font-size: 1.1rem; }
.epub-drop .epub-drop-sub { display: block; margin-top: .35rem; font-size: .85rem; }
.epub-drop input[type="file"] {
    position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px;
    overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; border: 0;
}
.epub-toolbar {
    display: flex; flex-wrap: wrap; align-items: center; gap: .35rem;
    padding: .4rem .55rem;
    background: var(--surface-color);
    border: 1px solid var(--border-color);
    border-radius: 6px 6px 0 0;
}
.epub-toolbar .epub-book-title {
    margin-right: auto; font-weight: var(--font-weight-semibold); font-size: .9rem;
    max-width: 45%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.epub-btn {
    display: inline-flex; align-items: center; justify-content: center;
    min-width: 2rem; height: 2rem; padding: 0 .55rem;
    background: none; border: 1px solid var(--border-color); border-radius: 4px;
    color: var(--text-color); font: inherit; font-size: .8rem; cursor: pointer;
    transition: color .15s ease, border-color .15s ease;
}
.epub-btn:hover { color: var(--link-color); border-color: var(--link-color); }
.epub-btn:focus-visible { outline: 3px solid var(--link-color); outline-offset: 2px; }
.epub-page-info { font: var(--font-weight-normal) .78rem var(--font-mono); color: var(--secondary-text); padding: 0 .25rem; }
.epub-toc {
    position: absolute; z-index: 20; top: 0; left: 0; width: min(20rem, 100%);
    max-height: 55vh; overflow-y: auto;
    background: var(--surface-color);
    border: 1px solid var(--border-color); border-radius: 0 0 6px 6px;
    box-shadow: 0 6px 16px -4px rgba(0, 0, 0, .25);
}
.epub-toc ul { list-style: none; margin: .35rem 0; padding-left: .9rem; }
.epub-toc > ul { padding-left: .4rem; }
.epub-toc a {
    display: block; padding: .3rem .45rem; border-radius: 4px;
    color: var(--link-color); text-decoration: none; font-size: .88rem;
}
.epub-toc a:hover { background: var(--code-bg); }
.epub-toc .epub-toc-label { padding: .3rem .45rem; color: var(--text-color); font-weight: var(--font-weight-semibold); font-size: .88rem; }
.epub-toc-wrap { position: relative; }
.epub-viewport {
    position: relative;
    height: clamp(340px, 68vh, 780px);
    background: var(--card-bg);
    border: 1px solid var(--border-color); border-top: none;
    border-radius: 0 0 6px 6px;
    overflow: hidden;
}
.epub-viewport iframe { width: 100%; height: 100%; border: 0; }
.epub-status { margin: .5rem 0 0; font-size: .85rem; color: var(--secondary-text); min-height: 1.1em; }
.epub-status:empty { min-height: 0; margin: 0; }
[hidden] { display: none !important; }
</style>

<div id="epub-library">
  <label class="epub-drop" id="epub-drop" for="epub-file">
    <span class="epub-drop-title">Drop an EPUB here</span>
    <span class="epub-drop-sub">…or click to choose a file. It stays on your device — nothing is uploaded.</span>
    <input type="file" id="epub-file" accept=".epub,application/epub+zip">
  </label>
</div>

<div id="epub-reader" hidden>
  <div class="epub-toolbar">
    <span class="epub-book-title" id="epub-book-title">Book</span>
    <button type="button" class="epub-btn" id="epub-prev" aria-label="Previous page">← Prev</button>
    <button type="button" class="epub-btn" id="epub-next" aria-label="Next page">Next →</button>
    <span class="epub-page-info" id="epub-page-info"></span>
    <button type="button" class="epub-btn" id="epub-toc-btn">Contents</button>
    <button type="button" class="epub-btn" id="epub-zoom-out" aria-label="Decrease text size">A−</button>
    <button type="button" class="epub-btn" id="epub-zoom-in" aria-label="Increase text size">A+</button>
    <button type="button" class="epub-btn" id="epub-close">Choose another</button>
  </div>
  <div class="epub-toc-wrap">
    <nav class="epub-toc" id="epub-toc" hidden aria-label="Table of contents"></nav>
  </div>
  <div class="epub-viewport" id="epub-viewport" aria-label="Book pages"></div>
</div>

<p class="epub-status" id="epub-status" role="status"></p>

</div>

<script src="/epub-reader/jszip.min.js"></script>
<script src="/epub-reader/epub.min.js"></script>
<script src="/epub-reader/reader.js"></script>

## How it works

The page uses [epub.js](https://github.com/futurepress/epub.js/) (self-hosted, no external requests) to unpack the EPUB in memory, paginate each chapter like printed pages, and render them into the box above.

## Fine print

- Works best with DRM-free EPUBs (DRM-protected files won't open — that's the point of DRM).
- Your reading position is remembered per book in your browser's local storage, so you can come back tomorrow and continue where you left off.
- The reader follows this site's palette — switch the theme and the book pages restyle to match.

---
title: "Strict Vertical Curvy Corners Navigation — TOC Design"
date: 2026-07-26
draft: false
tags: ["toc", "design", "navigation", "svg", "scrollspy", "intersectionobserver"]
categories: ["Tech"]
viewMode: docs
showToc: false
---

This post demonstrates a strict vertical Table of Contents design with smooth cubic Bézier S-curves connecting heading levels. The vertical lines stay perfectly straight (│) while diagonals transition smoothly (╲ or ╱) using cubic Bézier curves with vertically-aligned control points for perfect tangent continuity.

## Features Demonstrated

- **Strict vertical lines** (│) at each TOC item position
- **Smooth S-curve transitions** between heading levels using cubic Bézier curves
- **Vertically-aligned control points** for perfect tangent continuity
- **IntersectionObserver-based ScrollSpy** with rootMargin for precise activation
- **Smooth SVG path animation** with `transition: d 0.35s cubic-bezier(0.4, 0, 0.2, 1)`
- **Drop shadow glow** on active path segment
- **Sidebar auto-scroll** to keep active item visible

{{< rawhtml >}}
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Strict Vertical Curvy Corners Navigation</title>
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    html {
      scroll-behavior: smooth;
    }

    body {
      background-color: #0b0f17;
      color: #94a3b8;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      line-height: 1.6;
    }

    .layout-container {
      max-width: 1100px;
      margin: 0 auto;
      padding: 3rem 2rem;
      display: grid;
      grid-template-columns: 1fr 280px;
      gap: 4rem;
      border: 2px solid #1e293b;
      border-radius: 12px;
      background: #0e141f;
    }

    .article-content {
      color: #cbd5e1;
    }

    .article-content h1 {
      font-size: 2.25rem;
      color: #f8fafc;
      margin-bottom: 1.5rem;
    }

    .article-content section {
      margin-bottom: 3.5rem;
      padding-top: 1rem;
    }

    .article-content h2 {
      font-size: 1.5rem;
      color: #f1f5f9;
      margin-bottom: 0.75rem;
    }

    .article-content h3 {
      font-size: 1.15rem;
      color: #e2e8f0;
      margin-bottom: 0.5rem;
      margin-top: 1.25rem;
    }

    .article-content p {
      margin-bottom: 1rem;
      color: #94a3b8;
    }

    .toc-sidebar {
      position: sticky;
      top: 2rem;
      align-self: start;
      max-height: calc(100vh - 4rem);
      overflow-y: auto;
      padding-right: 0.5rem;
    }

    .toc-sidebar::-webkit-scrollbar {
      width: 4px;
    }
    .toc-sidebar::-webkit-scrollbar-thumb {
      background: #1e293b;
      border-radius: 2px;
    }

    .toc-title {
      font-size: 0.85rem;
      font-weight: 700;
      letter-spacing: 0.05em;
      text-transform: uppercase;
      color: #f1f5f9;
      margin-bottom: 1.25rem;
    }

    .toc-container {
      position: relative;
    }

    .toc-svg {
      position: absolute;
      left: 0;
      top: 0;
      width: 40px;
      height: 100%;
      pointer-events: none;
      overflow: visible;
    }

    .bg-path {
      stroke: #1e293b;
      stroke-width: 2.5px;
      fill: none;
      stroke-linecap: round;
      stroke-linejoin: round;
    }

    .active-path {
      stroke: #10b981;
      stroke-width: 2.5px;
      fill: none;
      stroke-linecap: round;
      stroke-linejoin: round;
      filter: drop-shadow(0px 0px 8px rgba(16, 185, 129, 0.6));
      transition: d 0.35s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .toc-list {
      list-style: none;
      padding-left: 28px;
    }

    .toc-item {
      display: flex;
      align-items: center;
      min-height: 38px;
    }

    .toc-item.nested {
      padding-left: 1.25rem;
    }

    .toc-link {
      font-size: 0.88rem;
      color: #64748b;
      text-decoration: none;
      transition: color 0.2s ease, transform 0.2s ease;
      display: block;
      padding: 0.2rem 0;
    }

    .toc-link:hover {
      color: #e2e8f0;
    }

    .toc-item.active .toc-link {
      color: #10b981;
      font-weight: 600;
      transform: translateX(2px);
    }
  </style>
</head>
<body>

  <div class="layout-container">
    <main class="article-content">
      <h1>Documentation Guide</h1>

      <section id="introduction">
        <h2>Introduction</h2>
        <p>Welcome to the component documentation. This guide will walk you through setup, configuration, and advanced usage examples.</p>
      </section>

      <section id="getting-started">
        <h2>Getting Started</h2>
        <p>To start using the UI components, install the library package via your preferred package manager and import the base stylesheets into your root component.</p>
      </section>

      <section id="usage">
        <h2>Usage</h2>
        <p>Basic usage examples showing how to import, mount, and configure basic properties for standard web applications.</p>
      </section>

      <section id="api">
        <h2>API Reference</h2>
        <p>Detailed API reference covering all available properties, slots, emitted events, and programmatic instance methods.</p>

        <div id="props">
          <h3>Props</h3>
          <p>Pass dynamic properties to control themes, layout variants, behavior flags, and custom dimensions.</p>
        </div>

        <div id="slots">
          <h3>Slots</h3>
          <p>Utilize named slots to inject custom HTML elements, icons, or nested components into designated layout areas.</p>
        </div>

        <div id="events">
          <h3>Events</h3>
          <p>Listen for key lifecycle events such as click, scroll, change, and validation callbacks.</p>
        </div>
      </section>

      <section id="theme">
        <h2>Theme Configuration</h2>
        <p>Customize primary colors, dark mode tokens, typography variables, and component radius parameters.</p>

        <div id="dark-mode">
          <h3>Dark Mode</h3>
          <p>Automatic dark mode toggle support using CSS variables or system color preference media queries.</p>
        </div>

        <div id="custom-styles">
          <h3>Custom Styles</h3>
          <p>Override default utility classes or append custom CSS rules for specific brand integration needs.</p>
        </div>
      </section>

      <section id="troubleshooting">
        <h2>Troubleshooting</h2>
        <p>Common issues, installation warnings, dependency conflicts, and their quick resolution steps.</p>
      </section>

      <section id="changelog">
        <h2>Changelog</h2>
        <p>Version release notes, bug fixes, breaking changes, and performance optimization details.</p>
      </section>
    </main>

    <aside class="toc-sidebar">
      <h2 class="toc-title">On this page</h2>

      <div class="toc-container">
        <svg class="toc-svg" id="toc-svg">
          <path class="bg-path" id="bg-path" />
          <path class="active-path" id="active-path" />
        </svg>

        <ul class="toc-list" id="toc-list">
          <li class="toc-item" data-indent="false"><a href="#introduction" class="toc-link">Introduction</a></li>
          <li class="toc-item" data-indent="false"><a href="#getting-started" class="toc-link">Getting Started</a></li>
          <li class="toc-item" data-indent="false"><a href="#usage" class="toc-link">Usage</a></li>
          <li class="toc-item" data-indent="false"><a href="#api" class="toc-link">API Reference</a></li>
          <li class="toc-item nested" data-indent="true"><a href="#props" class="toc-link">Props</a></li>
          <li class="toc-item nested" data-indent="true"><a href="#slots" class="toc-link">Slots</a></li>
          <li class="toc-item nested" data-indent="true"><a href="#events" class="toc-link">Events</a></li>
          <li class="toc-item" data-indent="false"><a href="#theme" class="toc-link">Theme</a></li>
          <li class="toc-item nested" data-indent="true"><a href="#dark-mode" class="toc-link">Dark Mode</a></li>
          <li class="toc-item nested" data-indent="true"><a href="#custom-styles" class="toc-link">Custom Styles</a></li>
          <li class="toc-item" data-indent="false"><a href="#troubleshooting" class="toc-link">Troubleshooting</a></li>
          <li class="toc-item" data-indent="false"><a href="#changelog" class="toc-link">Changelog</a></li>
        </ul>
      </div>
    </aside>
  </div>

<script>
  const OUTER_X = 2;   // Outer vertical axis |
  const INNER_X = 22;  // Nested vertical axis |

  const tocList = document.getElementById("toc-list");
  const items = Array.from(document.querySelectorAll(".toc-item"));
  const bgPath = document.getElementById("bg-path");
  const activePath = document.getElementById("active-path");
  const svg = document.getElementById("toc-svg");
  const sidebar = document.querySelector(".toc-sidebar");

  function getItemCoords(item) {
    const isNested = item.dataset.indent === "true";
    const x = isNested ? INNER_X : OUTER_X;
    const y = item.offsetTop + item.offsetHeight / 2;
    return { x, y };
  }

  /**
   * Generates a ultra-smooth path using cubic Bezier S-curves
   * that maintain strict vertical lines (|) at the nodes and
   * smooth diagonal transitions (\ or /) between levels.
   */
  function generateSmoothDiagonalPath(itemArray) {
    if (itemArray.length === 0) return "";

    let d = "";
    const first = getItemCoords(itemArray[0]);
    d += `M ${first.x},${first.y} `;

    for (let i = 0; i < itemArray.length - 1; i++) {
      const curr = getItemCoords(itemArray[i]);
      const next = getItemCoords(itemArray[i + 1]);

      if (curr.x !== next.x) {
        const dy = next.y - curr.y;
        
        // Midpoint Y where the diagonal transition occurs
        const startY = curr.y + dy * 0.2;
        const endY = curr.y + dy * 0.8;
        const midY = (startY + endY) / 2;

        // 1. Strict vertical line down (|) to start of diagonal curve
        d += `L ${curr.x},${startY} `;

        // 2. Smooth Cubic Bezier S-curve blending vertical (|) -> diagonal (\ or /) -> vertical (|)
        // Control points are vertically aligned with start and end axes for 100% tangent smoothness
        d += `C ${curr.x},${midY} ${next.x},${midY} ${next.x},${endY} `;

        // 3. Continue strict vertical line down (|) to next item position
        d += `L ${next.x},${next.y} `;
      } else {
        // Strict vertical straight line (|)
        d += `L ${next.x},${next.y} `;
      }
    }

    return d;
  }

  function updateSVG() {
    svg.style.height = `${tocList.offsetHeight}px`;

    // Static background path
    bgPath.setAttribute("d", generateSmoothDiagonalPath(items));

    // Active highlighted path
    const activeItems = items.filter(item => item.classList.contains("active"));

    if (activeItems.length > 0) {
      const firstIdx = items.indexOf(activeItems[0]);
      const lastIdx = items.indexOf(activeItems[activeItems.length - 1]);
      const activeRange = items.slice(firstIdx, lastIdx + 1);

      activePath.setAttribute("d", generateSmoothDiagonalPath(activeRange));
    } else {
      activePath.setAttribute("d", "");
    }
  }

  // ScrollSpy with IntersectionObserver
  const sectionTargets = items.map(item => {
    const id = item.querySelector("a").getAttribute("href").replace("#", "");
    return document.getElementById(id);
  }).filter(Boolean);

  let activeId = "";

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          activeId = entry.target.id;
        }
      });

      if (!activeId) return;

      let activeReached = false;
      let activeItemEl = null;

      items.forEach((item) => {
        const href = item.querySelector("a").getAttribute("href");
        if (href === `#${activeId}`) {
          activeReached = true;
          activeItemEl = item;
        }

        if (!activeReached || href === `#${activeId}`) {
          item.classList.add("active");
        } else {
          item.classList.remove("active");
        }
      });

      updateSVG();

      if (activeItemEl) {
        const sidebarBounds = sidebar.getBoundingClientRect();
        const itemBounds = activeItemEl.getBoundingClientRect();

        if (itemBounds.top < sidebarBounds.top || itemBounds.bottom > sidebarBounds.bottom) {
          activeItemEl.scrollIntoView({ block: "nearest", behavior: "smooth" });
        }
      }
    },
    { rootMargin: "-10% 0px -65% 0px", threshold: 0.1 }
  );

  sectionTargets.forEach((section) => observer.observe(section));

  window.addEventListener("resize", updateSVG);
  updateSVG();
</script>

  
</body>
</html>
{{< /rawhtml >}}
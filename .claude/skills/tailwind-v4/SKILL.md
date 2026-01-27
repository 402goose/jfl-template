---
name: tailwind-v4
description: Tailwind CSS v4 best practices and CSS-first configuration. Use when writing styles, setting up projects, or migrating from v3. Triggers on Tailwind setup, styling, theming, or CSS configuration tasks.
license: MIT
metadata:
  author: jfl
  version: "1.0.0"
---

# Tailwind CSS v4 Guidelines

Tailwind CSS v4.0 (released Jan 22, 2025) is a complete rewrite with CSS-first configuration, better performance, and modern CSS features.

## When to Apply

Reference these guidelines when:
- Setting up a new project with Tailwind
- Writing or reviewing Tailwind styles
- Configuring themes, colors, or design tokens
- Migrating from Tailwind v3
- Optimizing build performance

## Critical Changes from v3

### 1. CSS-First Configuration (No tailwind.config.js)

**OLD (v3):**
```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        brand: '#3b82f6',
      },
    },
  },
}
```

**NEW (v4):**
```css
/* styles.css */
@import "tailwindcss";

@theme {
  --color-brand: #3b82f6;
}
```

### 2. Single Import (No @tailwind directives)

**OLD (v3):**
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

**NEW (v4):**
```css
@import "tailwindcss";
```

### 3. Vite Plugin (Recommended)

```bash
npm install tailwindcss @tailwindcss/vite
```

```ts
// vite.config.ts
import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [tailwindcss()],
})
```

## CSS-First Configuration Reference

### Defining Theme Variables

```css
@import "tailwindcss";

@theme {
  /* Colors */
  --color-brand: #3b82f6;
  --color-brand-light: #60a5fa;
  --color-brand-dark: #1d4ed8;

  /* Fonts */
  --font-sans: "Inter", sans-serif;
  --font-mono: "Fira Code", monospace;

  /* Spacing */
  --spacing-18: 4.5rem;
  --spacing-22: 5.5rem;

  /* Border Radius */
  --radius-4xl: 2rem;

  /* Shadows */
  --shadow-glow: 0 0 20px rgba(59, 130, 246, 0.5);

  /* Animations */
  --animate-fade-in: fade-in 0.3s ease-out;
}

@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}
```

### Custom Variants

```css
@custom-variant dark (&:where(.dark, .dark *));
@custom-variant hocus (&:hover, &:focus);
```

### Using Legacy Config (if needed)

```css
@import "tailwindcss";
@config "./tailwind.config.js";
```

## New Features in v4

### Dynamic Utility Values

No more extending config for one-off values:
```html
<!-- Works without config -->
<div class="mt-[17px] w-[calc(100%-2rem)] bg-[#1a1a2e]">
```

### Container Queries (Built-in)

```html
<div class="@container">
  <div class="@sm:flex @lg:grid @lg:grid-cols-3">
    <!-- Responsive to container, not viewport -->
  </div>
</div>
```

### 3D Transforms

```html
<div class="rotate-x-45 rotate-y-12 translate-z-10 perspective-500">
```

### Gradient Improvements

```html
<!-- Radial gradients -->
<div class="bg-radial-gradient from-blue-500 to-transparent">

<!-- Conic gradients -->
<div class="bg-conic-gradient from-red-500 via-yellow-500 to-green-500">
```

### @starting-style (CSS Transitions)

```html
<div class="starting:opacity-0 starting:scale-95 transition-all">
  <!-- Animates on mount -->
</div>
```

### not-* Variant

```html
<div class="not-hover:opacity-50">
  <!-- 50% opacity when NOT hovered -->
</div>

<button class="not-disabled:cursor-pointer">
```

### P3 Color Palette

New wider-gamut colors available:
```html
<div class="bg-blue-500">  <!-- Now uses P3 color space -->
```

## Project Setup (Quick Start)

### Vite + React

```bash
npm create vite@latest my-app -- --template react-ts
cd my-app
npm install tailwindcss @tailwindcss/vite
```

```ts
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
})
```

```css
/* src/index.css */
@import "tailwindcss";
```

### Next.js

```bash
npx create-next-app@latest my-app
cd my-app
npm install tailwindcss @tailwindcss/postcss
```

```js
// postcss.config.js
module.exports = {
  plugins: {
    '@tailwindcss/postcss': {},
  },
}
```

```css
/* app/globals.css */
@import "tailwindcss";
```

## Migration from v3

### Automated Migration

```bash
npx @tailwindcss/upgrade
```

### Manual Checklist

1. **Remove tailwind.config.js** - Move to CSS @theme
2. **Update CSS imports** - `@import "tailwindcss"` replaces directives
3. **Update plugins** - Use `@tailwindcss/vite` or `@tailwindcss/postcss`
4. **Check browser support** - v4 requires modern browsers (no IE11)
5. **Update custom colors** - Use CSS variables in @theme
6. **Remove safelist/corePlugins** - Not supported in v4

### Breaking Changes

| Feature | v3 | v4 |
|---------|----|----|
| Config file | `tailwind.config.js` | CSS `@theme` |
| CSS import | `@tailwind base/components/utilities` | `@import "tailwindcss"` |
| Template paths | Manual config | Auto-discovered |
| IE11 support | Yes | No |
| Safari < 16.4 | Yes | No |
| `corePlugins` | Supported | Removed |
| `safelist` | Supported | Removed |

## Best Practices

### DO

- Use `@theme` for all design tokens
- Use CSS variables for dynamic values
- Use container queries for component-level responsiveness
- Use the Vite plugin for best DX
- Take advantage of dynamic values `w-[calc(100%-2rem)]`

### DON'T

- Create tailwind.config.js unless migrating legacy code
- Use arbitrary values for repeated patterns (define in @theme)
- Rely on IE11 or old Safari support
- Mix v3 and v4 configuration patterns

## Performance Notes

- **Faster builds**: Uses Lightning CSS under the hood
- **Smaller output**: CSS variables reduce duplication
- **No runtime**: Still zero-runtime, all compile-time
- **Incremental**: Much faster incremental rebuilds

## Resources

- [Official v4 Docs](https://tailwindcss.com/docs)
- [v4 Blog Post](https://tailwindcss.com/blog/tailwindcss-v4)
- [Migration Guide](https://tailwindcss.com/docs/upgrade-guide)
- [Playground](https://play.tailwindcss.com/)

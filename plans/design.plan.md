# Phase 1: Design System Plan

**Status**: PENDING  
**Agent**: Codex  
**Output**: design-tokens.json, admin/src/index.css, mobile/lib/core/theme/

---

## Context

Al-Safa Residence is a clean/minimal property management platform. The design reference is:
`~/safa residence/AlSafa_Design 2.html` — a full HTML mock with all screens for mobile, admin, and security guard views.

Enhance the design — do not copy 1:1. Dark mode is required.

---

## Files to Read First

1. `PROJECT.md` — design tokens section
2. `~/safa residence/AlSafa_Design 2.html` — full design reference (read CSS variables at top)

---

## Color Tokens

```
primary:        #1B3A6B  (Navy blue)
primary-light:  #EEF2F8
secondary:      #2D5EA8
accent:         #C9A96E  (Gold)
gold-gradient:  linear-gradient(135deg, #D4AF7A, #C9A96E, #B8924A)
bg:             #F5F6F8
surface:        #FFFFFF
sidebar:        #0F1F3D  (Dark navy sidebar)
dark-bg:        #0B0D10  (Dark mode page background)
text:           #111827
text-muted:     #6B7280
text-subtle:    #9CA3AF
success:        #16A34A
warning:        #D97706
danger:         #DC2626
gate-approved:  #16A34A
gate-guest:     #1D4ED8
gate-denied:    #DC2626
gate-waiting:   #D97706
```

---

## Tasks

### 1. Generate design-tokens.json (project root)

Format:
```json
{
  "colors": { ... },
  "typography": { "fontFamily": "Inter", "scale": { ... } },
  "spacing": { ... },
  "radius": { ... },
  "shadows": { ... }
}
```

### 2. Generate admin/src/index.css

Tailwind CSS v4 `@theme` block with all color variables. Include light and dark mode variants.

Pattern (hala-dashboard style):
```css
@import "tailwindcss";

@theme {
  --color-primary: #1B3A6B;
  --color-accent: #C9A96E;
  /* ... all tokens */
}

/* Dark mode overrides */
.dark {
  --color-bg: #0B0D10;
  /* ... */
}
```

### 3. Generate mobile/lib/core/theme/app_colors.dart

```dart
abstract class AppColors {
  static const Color primary = Color(0xFF1B3A6B);
  static const Color accent = Color(0xFFC9A96E);
  // ... all colors
  
  // Dark mode
  static const Color darkBackground = Color(0xFF0B0D10);
  static const Color darkSurface = Color(0xFF111827);
}
```

### 4. Generate mobile/lib/core/theme/app_theme.dart

Full ThemeData for light and dark modes using the color tokens.

---

## Acceptance Criteria

- [ ] design-tokens.json exists at project root with all color, typography, spacing tokens
- [ ] admin/src/index.css has @theme block compatible with Tailwind CSS v4
- [ ] mobile/lib/core/theme/app_colors.dart has all color constants
- [ ] mobile/lib/core/theme/app_theme.dart has ThemeData for light + dark
- [ ] Dark mode colors are usable (sufficient contrast, not just inverted)

---

## Commit Message

```
feat(design): generate design system from Al-Safa reference
```

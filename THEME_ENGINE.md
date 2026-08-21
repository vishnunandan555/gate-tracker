# Comprehensive Theme Engine Architecture & Specifications

## 1. Overview & Architecture Philosophy

The Gateletics Theme Engine is a robust, modular, and fully deterministic design system built for Flutter. It completely replaces legacy partial theme overrides with explicit, immutable **ThemeSets** and independent **Mode-Aware Accent Pools**.

```
                        ┌──────────────────────────────┐
                        │   lib/core/theme/theme_sets/ │
                        │   - standard_dark_theme      │
                        │   - standard_light_theme     │
                        └──────────────┬───────────────┘
                                       │
                                       ▼
                        ┌──────────────────────────────┐
                        │  lib/core/theme/presets/     │
                        │  - handcrafted_presets.dart  │
                        └──────────────┬───────────────┘
                                       │ (Theme Registry)
                                       ▼
                        ┌──────────────────────────────┐
                        │    ThemeEngineNotifier       │
                        │  (Riverpod State Provider)   │
                        └──────────────┬───────────────┘
                                       │
               ┌───────────────────────┴───────────────────────┐
               ▼                                               ▼
   ┌───────────────────────┐                       ┌───────────────────────┐
   │ lightAppThemeProvider │                       │ darkAppThemeProvider  │
   └───────────┬───────────┘                       └───────────┬───────────┘
               │                                               │
               ▼                                               ▼
ThemeData (Standard Light Set)                  ThemeData (Standard Dark Set)
+ Light Accent Pool                             + Dark Accent Pool
               │                                               │
               └───────────────────────┬───────────────────────┘
                                       │
                                       ▼
                           ┌───────────────────────┐
                           │   AppTheme.buildTheme │
                           │  (ThemeExtension)     │
                           └───────────┬───────────┘
                                       │
                                       ▼
                           ┌───────────────────────┐
                           │   MaterialApp.router  │
                           │   (ThemeMode.system)  │
                           └───────────┬───────────┘
                                       │
                                       ▼
                           ┌───────────────────────┐
                           │   UI Widgets          │
                           │  (context.appColors)  │
                           └───────────────────────┘
```

### Core Design Rules:
1. **System Dynamic Default**: By default, the app operates in `ThemeMode.system`, automatically adapting to the user device's System Light/Dark setting.
2. **No Base Theme Ambiguity**: Every theme is an explicit `ThemeSetModel` containing exact definitions for every UI layer (Scaffold Canvas, L1 Cards, L2 Inputs, L3 Dialogs, Text hierarchy, Borders). There is no fallback guessing or partial color inheritance.
3. **Dual Independent Accent Pools**: Accent colors are completely decoupled from surface theme sets. Light Mode accents (`defaultLightAccents`) and Dark Mode accents (`defaultDarkAccents`) live in separate pools. Adding a custom accent targets either Light Mode or Dark Mode specifically.
4. **Material You Monet Integration**: Supports native OS dynamic accent extraction (`darkDynamic.primary` / `lightDynamic.primary`) alongside manual color selection, boot accent randomization, and freeze locking.
5. **Modular Developer Theme Files**: Custom themes are self-contained Dart files located in `lib/core/theme/theme_sets/`. Developers can create new theme files using the provided template file.
6. **Live Reactive Modal Sync**: Open bottom sheets and popups are wrapped in a reactive Theme widget so ModalRoutes receive live theme updates synchronously when switching between Light, Dark, or System mode.
7. **Native Overlay & Smooth Lerp**: System status bars and navigation bars (`SystemChrome`) auto-sync contrast with the active theme, and theme switches execute with smooth Lerp curves.

---

## 2. Directory & File Map

All theme architecture files reside cleanly in `lib/core/theme/`:

```
lib/core/theme/
├── models/
│   ├── theme_set_model.dart            # Immutable ThemeSet specification model
│   └── accent_pool_model.dart         # Dual accent pools, Hex parser, & contrast safeguard
├── theme_sets/
│   ├── custom_theme_template.dart      # Developer custom theme file template
│   ├── standard_dark_theme.dart        # Base fail-safe Dark theme
│   └── standard_light_theme.dart       # Base fail-safe Light theme
├── presets/
│   └── handcrafted_presets.dart        # Central ThemeRegistry (Standard Dark & Light)
├── app_theme.dart                     # ThemeData builder & System UI status bar auto-sync
├── app_theme_colors.dart              # ThemeExtension with Lerp curves & WCAG contrast
└── theme_context_ext.dart             # BuildContext extension (context.appColors)
```

---

## 3. Surface Tier Inheritance & Visual Matrix

UI components derive their background and contrast colors based on an explicit 4-tier surface stacking model:

```
 ┌────────────────────────────────────────────────────────────────────────┐
 │ L3 OVERLAY TIER (dialogBackground)                                    │
 │ Floating Popups, AlertDialogs, BottomSheets                           │
 │ Dark: #131316  │  Light: #FFFFFF                                      │
 │ ┌────────────────────────────────────────────────────────────────────┐ │
 │ │ L2 INTERACTIVE TIER (surfaceColor)                                 │ │
 │ │ Text Fields, Chips, Dropdown Menus, Buttons                        │ │
 │ │ Dark: #18181B  │  Light: #F1F5F9                                   │ │
 │ │ ┌────────────────────────────────────────────────────────────────┐ │ │
 │ │ │ L1 CARD TIER (cardBackground)                                  │ │ │
 │ │ │ Stats Cards, Category Cards, Syllabus Topic Tiles              │ │ │
 │ │ │ Dark: #131316  │  Light: #FFFFFF                                │ │ │
 │ │ │ ┌────────────────────────────────────────────────────────────┐ │ │ │
 │ │ │ │ BASE CANVAS TIER (scaffoldBackground)                        │ │ │ │
 │ │ │ │ App Scaffold, Navigation Drawer, Main Background          │ │ │ │
 │ │ │ │ Dark: #09090B  │  Light: #F8FAFC                            │ │ │ │
 │ │ │ └────────────────────────────────────────────────────────────┘ │ │ │
 │ │ └────────────────────────────────────────────────────────────────┘ │ │
 │ └────────────────────────────────────────────────────────────────────┘ │
 └────────────────────────────────────────────────────────────────────────┘
```

| Tier / Element | Property Name | Description & Purpose | Standard Dark | Standard Light |
| :--- | :--- | :--- | :--- | :--- |
| **Canvas** | `scaffoldBackground` | Main app background, drawer, root view canvas | `0xFF09090B` | `0xFFF8FAFC` |
| **L1 Surface** | `cardBackground` | Main content cards, stats cards, syllabus tiles | `0xFF131316` | `0xFFFFFFFF` |
| **L2 Surface** | `surfaceColor` | Interactive elements, text field inputs, chips | `0xFF18181B` | `0xFFF1F5F9` |
| **L3 Surface** | `dialogBackground` | Floating popups, AlertDialogs, BottomSheets | `0xFF131316` | `0xFFFFFFFF` |
| **Primary Text** | `textPrimary` | High-contrast headers, primary titles | `0xFFF1F5F9` | `0xFF0F172A` |
| **Secondary Text** | `textSecondary` | Subtitles, secondary metadata labels | `0xFF94A3B8` | `0xFF475569` |
| **Muted Text** | `textMuted` | Disabled items, input placeholders, captions | `0xFF64748B` | `0xFF64748B` |
| **Border Outline** | `borderColor` | Outer borders for cards, inputs, & dialogs | `0x1AFFFFFF` (10% White) | `0x1F000000` (12% Black) |
| **Divider Line** | `dividerColor` | Horizontal rule dividers between list items | `0x1AFFFFFF` (10% White) | `0x1A000000` (10% Black) |

---

## 4. Dual Accent Pools & Dynamic Accent Architecture

Accent colors are isolated from surface `ThemeSetModel` objects to ensure color customizations apply dynamically without altering background accessibility.

```
                           ┌───────────────────────────┐
                           │    AppAccentPools         │
                           └─────────────┬─────────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
     ┌───────────────────────┐                       ┌───────────────────────┐
     │   Dark Accent Pool    │                       │   Light Accent Pool   │
     ├───────────────────────┤                       ├───────────────────────┤
     │ Default: Bright Cyan  │                       │ Default: Dark Blue    │
     │ (#00F0FF)             │                       │ (#0284C7)             │
     │ + Custom Dark Accents │                       │ + Custom Light Accents│
     └───────────────────────┘                       └───────────────────────┘
```

### Initial Accent Pool Defaults & Curated Focus Palettes:
- **Dark Mode Curated Swatches**:
  - `Cyber Cyan` (`0xFF00F0FF`)
  - `Emerald Focus` (`0xFF10B981`)
  - `Electric Violet` (`0xFF8B5CF6`)
  - `Sunset Rose` (`0xFFF43F5E`)
  - `Solar Amber` (`0xFFF59E0B`)
  - `Arctic Sky` (`0xFF38BDF8`)
- **Light Mode Curated Swatches**:
  - `Deep Ocean` (`0xFF0284C7`)
  - `Forest Emerald` (`0xFF059669`)
  - `Royal Violet` (`0xFF6D28D9`)
  - `Crimson Rose` (`0xFFE11D48`)
  - `Deep Amber` (`0xFFD97706`)
  - `Cobalt Indigo` (`0xFF4338CA`)

### Custom Hex `#` Accent Entry:
Users can add custom accent colors with direct Hex code entry (e.g. `#00F0FF`) or RGB sliders in the Accent Color dialog. Custom accents are stored in `SharedPreferences` under `custom_dark_accents_list` or `custom_light_accents_list`.

### Contrast Safeguard (`ensureContrast`):
When a custom accent color is selected, `AppAccentPools.ensureContrast()` calculates its HSL lightness value and automatically adjusts it if its contrast against the target scaffold background fails WCAG standards.

### Contrast On-Accent Calculation:
`AppThemeColors` computes luminance dynamically to select the optimal text/icon color overlay (`Colors.black` for high-luminance accents, `Colors.white` for dark accents).

---

## 5. Frosted Glassmorphism UI Component (`GlassContainer`)

The `GlassContainer` widget provides a unified frosted-glass aesthetic powered by `BackdropFilter` and translucent surface layers:
- **Automatic Theme Sync**: Follows `context.appColors.enableGlassmorphism`. When disabled (default for base themes), automatically renders lightweight solid card backgrounds without backdrop blur performance overhead.
- **Translucent Tiering**: Applies adaptive alpha values (`0.65` light, `0.45` dark) with high-contrast highlight border outlines.

---

## 5. Live Modal Route Theme Inheritance Architecture

In Flutter, modal bottom sheets (`showModalBottomSheet`) push a new `ModalRoute` onto the `Navigator` stack. By default, modal routes inherit their initial `ThemeData` from the route context at the moment of creation and do not receive reactive updates when the parent `MaterialApp` changes mode.

To resolve this, modal route subtrees are wrapped in a reactive `Theme` builder bound to `activeAppThemeProvider`. This ensures theme changes propagate instantly into open modal sheets:

```
┌────────────────────────────────────────────────────────────────────────┐
│ Navigator Root Context                                                 │
│  └── MaterialApp (ThemeMode.system)                                    │
│       │                                                                │
│       ▼                                                                │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ ModalRoute (Pushed Overlay)                                      │  │
│  │  └── Theme (Bound to activeAppThemeProvider)                     │  │
│  │       └── AnimatedContainer (250ms Lerp Transition)              │  │
│  │            └── ThemeGallerySheet (context.appColors)             │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Developer Guide: Creating Custom Theme Files

To create custom theme files, developers duplicate and edit the template file `custom_theme_template.dart` located in `lib/core/theme/theme_sets/`.

### Registering in Preset Registry:
Add the newly instantiated theme model to `HandcraftedPresets.allPresets` in `lib/core/theme/presets/handcrafted_presets.dart` to make it selectable within the UI Theme Gallery.

---

## 7. Accessing Theme Colors in Widgets

In any Flutter widget, access active design system colors through `context.appColors`:

### Complete `AppThemeColors` Token Index:
- `appColors.scaffoldBackground` — Canvas Background
- `appColors.cardBackground` — L1 Card Surface
- `appColors.surfaceColor` — L2 Input / Chip Surface
- `appColors.dialogBackground` — L3 Floating Overlay Surface
- `appColors.textPrimary` — Primary Text
- `appColors.textSecondary` — Secondary Text
- `appColors.textMuted` — Muted / Placeholder Text
- `appColors.borderColor` — Border Outlines
- `appColors.dividerColor` — Separation Dividers
- `appColors.primaryAccent` — Active Accent Color
- `appColors.secondaryAccent` — Semi-transparent / Secondary Accent
- `appColors.onAccent` — Text / Icon Color on top of Accent (calculated luminance)
- `appColors.success` — Semantic Success Status (Emerald)
- `appColors.warning` — Semantic Warning Status (Amber)
- `appColors.error` — Semantic Error Status (Red)
- `appColors.info` — Semantic Info Status (Sky Blue)
- `appColors.isLight` — Boolean indicating if active theme is Light Mode

---

## 8. Typography Hierarchy & Material You Monet Seed Generation

### Typography Standard:
The typography stack is powered by `GoogleFonts.outfitTextTheme` with deterministic font weights, letter spacing, and line heights mapped directly to `textPrimary`, `textSecondary`, and `textMuted`:
- **Display & Headline**: `FontWeight.w700` with subtle negative letter spacing for modern editorial clarity.
- **Titles**: `FontWeight.w600` / `FontWeight.w500` for cards and modal headers.
- **Body**: `FontWeight.w400` with standardized `1.35x` - `1.4x` line heights for optimal reading comfort.
- **Labels**: `FontWeight.w500` / `FontWeight.w600` for buttons, badges, and input hints.

### Material You Monet Dynamic Seed Generation:
`AppTheme.buildTheme()` generates its underlying Flutter `ColorScheme` via `ColorScheme.fromSeed(seedColor: themeColors.primaryAccent, brightness: brightness)`. This produces a harmonized Material You tonal palette across the entire framework while preserving strict surface layer contrast definitions.

---

## 9. Full Codebase Theme Engine Migration Completed

A comprehensive, 100% project-wide theme engine migration was executed across all UI screens, widgets, custom canvas painters, dialogs, and navigation shells.

### Key Refactoring Highlights:
1. **0 Hardcoded Color Leaks:** All occurrences of hardcoded `Colors.white`, `Colors.white70`, dark container fills (`#141824`, `#16161A`), and fixed cyan accents were refactored to `context.appColors` tokens.
2. **Dynamic Light & Dark Surface Tiering:** Canvas, card surfaces, interactive text fields, and floating dialogs dynamically adapt their elevation and background fills between Light Mode and Dark Mode.
3. **Semantic Status Colors:** Unified `appColors.success`, `appColors.warning`, `appColors.error`, and `appColors.info` tokens ensure status indicators maintain contrast across themes.
4. **Luminance-Based Contrast Safeguards:** Custom canvas painters and accent pill chips dynamically calculate luminance or use `context.appColors.onAccent` to guarantee legible text on any user-selected accent color.

# Comprehensive Theme Engine Architecture & Specifications

## 1. Overview & Architecture Philosophy

The Gateletics Theme Engine is a robust, modular, and fully deterministic design system built for Flutter. It completely replaces legacy partial theme overrides with explicit, immutable **ThemeSets** and independent **Mode-Aware Accent Pools**.

```
                           ┌───────────────────────────┐
                           │    ThemeEngineNotifier    │
                           └─────────────┬─────────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
     ┌───────────────────────┐                       ┌───────────────────────┐
     │  lightAppThemeProvider│                       │  darkAppThemeProvider │
     └───────────┬───────────┘                       └───────────┬───────────┘
                 │                                               │
                 ▼                                               ▼
  ThemeData (Paper Light Set)                     ThemeData (Zinc Dark Set)
  + Light Accent Pool                             + Dark Accent Pool
                 │                                               │
                 └───────────────────────┬───────────────────────┘
                                         │
                                         ▼
                             ┌───────────────────────┐
                             │  MaterialApp.router   │
                             │   (ThemeMode.system)  │
                             └───────────────────────┘
```

### Core Design Rules:
1. **System Dynamic Default**: By default, the app operates in `ThemeMode.system`, automatically adapting to the user device's System Light/Dark setting.
2. **No Base Theme Ambiguity**: Every theme is an explicit `ThemeSetModel` containing exact definitions for every UI layer (Scaffold Canvas, L1 Cards, L2 Inputs, L3 Dialogs, Text hierarchy, Borders). There is no fallback guessing or partial color inheritance.
3. **Dual Independent Accent Pools**: Accent colors are completely decoupled from surface theme sets. Light Mode accents (`defaultLightAccents`) and Dark Mode accents (`defaultDarkAccents`) live in separate pools. Adding a custom accent targets either Light Mode or Dark Mode specifically.
4. **Material You Monet Integration**: Supports native OS dynamic accent extraction (`darkDynamic.primary` / `lightDynamic.primary`) alongside manual color selection, boot accent randomization, and freeze locking.
5. **Modular Developer Theme Files**: Custom themes are self-contained Dart files located in `lib/core/theme/theme_sets/`. Developers can create new theme files using the provided template file.
6. **Live Reactive Modal Sync**: Open bottom sheets and popups are wrapped in `Theme(data: activeThemeData)` so ModalRoutes receive live theme updates synchronously when switching between Light, Dark, or System mode.
7. **Native Overlay & Smooth Lerp**: System status bars and navigation bars (`SystemChrome`) auto-sync contrast with the active theme, and theme switches execute with smooth 250ms `AppThemeColors.lerp` curves.

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
│   ├── standard_dark_theme.dart        # Base fail-safe Dark theme (Zinc)
│   └── standard_light_theme.dart       # Base fail-safe Light theme (Paper)
├── presets/
│   └── handcrafted_presets.dart        # Central ThemeRegistry (Standard Dark & Light)
├── app_theme.dart                     # ThemeData builder & System UI status bar auto-sync
├── app_theme_colors.dart              # ThemeExtension with 250ms Lerp curves & WCAG contrast
└── theme_context_ext.dart             # BuildContext extension (context.appColors)
```

---

## 3. Surface Tier Specification Matrix

Every `ThemeSetModel` explicitly defines 4 surface background tiers, 3 typography levels, and structural line opacities:

| Tier / Element | Property Name | Description & Purpose | Standard Dark (`zinc_dark`) | Standard Light (`paper_light`) |
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

Accent colors are managed outside of surface `ThemeSetModel` objects.

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
     │ + User Dark Accents   │                       │ + User Light Accents  │
     └───────────────────────┘                       └───────────────────────┘
```

### Initial Accent Pool Defaults:
- **Dark Mode Initial Accent**: Bright Cyan (`0xFF00F0FF`)
- **Light Mode Initial Accent**: Dark Blue (`0xFF0284C7`)

### Custom Hex `#` Accent Entry:
Users can add custom accent colors with direct Hex code entry (e.g. `#00F0FF`) or RGB sliders in the Accent Color dialog. Custom accents are stored in `SharedPreferences` under `custom_dark_accents_list` or `custom_light_accents_list`.

### Contrast Safeguard (`ensureContrast`):
When a custom accent color is selected, `AppAccentPools.ensureContrast()` calculates its HSL lightness value and automatically adjusts it if its contrast against the target scaffold background fails WCAG standards.

### Contrast On-Accent Calculation:
`AppThemeColors` computes luminance dynamically to select the optimal text/icon color overlay (`Colors.black` for high-luminance accents, `Colors.white` for dark accents).

---

## 5. Live Modal Route Theme Sync Architecture

In Flutter, opening a modal bottom sheet (`showModalBottomSheet`) creates an isolated `ModalRoute` sitting on top of the `Navigator` stack. By default, `ModalRoute` instances do not rebuild their internal theme context when the root `MaterialApp` changes themes.

To guarantee instant, live theme switching inside open modals:

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => Consumer(
    builder: (context, ref, child) {
      final activeThemeData = ref.watch(activeAppThemeProvider);

      return Theme(
        data: activeThemeData, // Passes active Light/Dark theme directly into ModalRoute!
        child: Builder(
          builder: (context) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: context.appColors.surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: context.appColors.borderColor),
              ),
              child: const ThemeGallerySheet(),
            );
          },
        ),
      );
    },
  ),
);
```

---

## 6. Developer Guide: Creating Custom Theme Files

To create custom theme files, developers duplicate and edit the template file [custom_theme_template.dart](file:///home/vishnunandan555/Projects/gate-tracker/lib/core/theme/theme_sets/custom_theme_template.dart) in `lib/core/theme/theme_sets/`:

```dart
const CustomThemeBundle myCustomBundle = CustomThemeBundle(
  id: 'my_custom_bundle',
  name: 'My Custom Theme',
  description: 'Custom paired theme specification.',
  darkTheme: ThemeSetModel(...),
  lightTheme: ThemeSetModel(...),
);
```

### Registering in Preset Registry:
Add the theme model to `HandcraftedPresets.allPresets` in `lib/core/theme/presets/handcrafted_presets.dart`:

```dart
class HandcraftedPresets {
  static const ThemeSetModel zincDark = standardDarkTheme;
  static const ThemeSetModel paperLight = standardLightTheme;

  static List<ThemeSetModel> get allPresets => [
        standardDarkTheme,
        standardLightTheme,
        myCustomDarkTheme, // Added custom theme file
      ];
}
```

---

## 7. Accessing Theme Colors in Widgets

In any Flutter widget, access the active design system colors through `context.appColors`:

```dart
Widget build(BuildContext context) {
  final appColors = context.appColors;

  return Container(
    color: appColors.cardBackground, // L1 Card Surface
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: appColors.borderColor),
    ),
    child: Text(
      "Card Title",
      style: TextStyle(
        color: appColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
```

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
- `appColors.onAccent` — Text / Icon Color on top of Accent
- `appColors.isLight` — Boolean indicating if active theme is Light Mode

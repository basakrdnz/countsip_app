# CountSip – UI Design Guide

**Inspiration:** iOS Calendar, Apple Reminders  
**Design Philosophy:** Clean, minimal, functional

---

## Color Palette

### Primary Colors
```dart
// lib/core/theme/app_colors.dart

class AppColors {
  // Primary
  static const primary = Color(0xFFFF6B35);      // Vibrant Orange (CTA buttons)
  static const primaryLight = Color(0xFFFF8A5B); // Light Orange (hover)
  static const primaryDark = Color(0xFFE65525);  // Dark Orange (pressed)
  
  // Background
  static const background = Color(0xFFF9F9F9);   // Off-white (main background)
  static const surface = Color(0xFFFFFFFF);      // Pure white (cards, modals)
  
  // Text
  static const textPrimary = Color(0xFF1C1C1E);  // Almost black
  static const textSecondary = Color(0xFF8E8E93); // Gray (secondary text)
  static const textTertiary = Color(0xFFC7C7CC); // Light gray (placeholders)
  
  // Borders
  static const border = Color(0xFFE5E5EA);       // Light gray border
  static const borderActive = Color(0xFFFF6B35); // Orange (selected state)
  
  // Status Colors
  static const success = Color(0xFF34C759);      // Green (accepted friend request)
  static const warning = Color(0xFFFF9500);      // Yellow (pending)
  static const error = Color(0xFFFF3B30);        // Red (errors)
  
  // Shadows
  static const shadow = Color(0x1A000000);       // 10% black (subtle shadows)
}
```

---

## Typography

### Text Styles
```dart
// lib/core/theme/app_text_styles.dart

class AppTextStyles {
  // Large Title (Screen headers)
  static const largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.textPrimary,
    letterSpacing: 0.4,
  );
  
  // Title 1 (Section headers)
  static const title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600, // Semibold
    color: AppColors.textPrimary,
  );
  
  // Title 2 (Card titles)
  static const title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Title 3 (List items)
  static const title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Body (Regular text)
  static const body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Callout (Cards, buttons)
  static const callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  
  // Subheadline (Secondary info)
  static const subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  
  // Footnote (Timestamps, small text)
  static const footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  
  // Caption 1 (Very small text)
  static const caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );
  
  // Caption 2 (Smallest text)
  static const caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );
}
```

---

## Spacing & Layout

### Standard Spacing
```dart
class AppSpacing {
  static const xs = 4.0;   // Tiny gaps
  static const sm = 8.0;   // Small gaps
  static const md = 16.0;  // Default spacing
  static const lg = 24.0;  // Large spacing
  static const xl = 32.0;  // Extra large
  static const xxl = 48.0; // Huge spacing
}
```

### Border Radius
```dart
class AppRadius {
  static const sm = 8.0;   // Small elements
  static const md = 12.0;  // Cards, buttons
  static const lg = 16.0;  // Modals
  static const xl = 24.0;  // Large containers
  static const round = 999.0; // Fully rounded (pills)
}
```

---

## Component Styles

### 1. Card (Entry Cards, Friend Cards)
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: AppColors.border, width: 1),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  padding: EdgeInsets.all(AppSpacing.md),
  // ... child content
)
```

### 2. Button (Primary)
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    elevation: 0, // Flat design
  ),
  onPressed: () {},
  child: Text('Log It!'),
)
```

### 3. Text Button (Secondary)
```dart
TextButton(
  style: TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
  ),
  onPressed: () {},
  child: Text('Request New Drink'),
)
```

### 4. Input Field
```dart
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: AppColors.surface,
    hintText: 'Venue (optional)',
    hintStyle: AppTextStyles.body.copyWith(
      color: AppColors.textTertiary,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
  ),
)
```

---

## Screen-Specific Designs

### Home Screen (Feed)

```
┌─────────────────────────────────────┐
│  CountSip              [🔔] (bell)  │ ← Navigation bar (white bg, shadow)
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐ │
│  │ [😊] John • 2h ago            │ │ ← Entry card
│  │ 2x Beer at Murphy's Pub 🍺    │ │
│  │ +2 pts                        │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ [😎] Sarah • 5h ago           │ │
│  │ 1x Cocktail at Home 🍹        │ │
│  │ +2 pts                        │ │
│  └───────────────────────────────┘ │
│                                     │
│  ... more entries ...               │
│                                     │
├─────────────────────────────────────┤
│ [🏠]  [🍻]  [🏆]  [👤]             │ ← Bottom tab bar
└─────────────────────────────────────┘
  Home  Add  Leaderboard  Profile
```

### Add Drink Modal

```
┌─────────────────────────────────────┐
│  [✕]         Log Drink         [✓]  │ ← Modal header
├─────────────────────────────────────┤
│                                     │
│  Choose Drink:                      │
│                                     │
│  ┌─────┬─────┬─────┐               │
│  │ 🍺  │ 🍷  │ 🥃  │               │ ← Icon grid (3x3)
│  │Beer │Wine │Whsky│               │
│  │ 1pt │ 2pt │ 3pt │               │
│  ├─────┼─────┼─────┤               │
│  │ 🍸  │ 🥃  │ 🍹  │               │
│  │Vodka│Tequi│Cockt│               │
│  │ 3pt │ 3pt │ 2pt │               │
│  ├─────┼─────┼─────┤               │
│  │ 🥃  │ 🥃  │ 🍻  │               │
│  │Shot │ Rakı│Other│               │
│  │ 2pt │ 3pt │ 1pt │               │
│  └─────┴─────┴─────┘               │
│                                     │
│  Request New Drink →                │ ← Text button
│                                     │
│  Quantity:                          │
│  ┌──────────────────┐               │
│  │  [−]   1   [+]   │               │ ← Stepper
│  └──────────────────┘               │
│                                     │
│  Venue:                             │
│  ┌──────────────────┐               │
│  │ Murphy's Pub     │               │ ← Text input
│  └──────────────────┘               │
│                                     │
│  Time:                              │
│  ┌──────────────────┐               │
│  │ Jan 7, 11:48 PM  │               │ ← Date/time picker
│  └──────────────────┘               │
│                                     │
│  ┌──────────────────┐               │
│  │    Log It! 🎉    │               │ ← Primary button
│  └──────────────────┘               │
│                                     │
└─────────────────────────────────────┘
```

### Leaderboard Screen

```
┌─────────────────────────────────────┐
│  Leaderboard    [Week ▾] [Month] [All]│ ← Segmented control
├─────────────────────────────────────┤
│                                     │
│  🥇  [😊] John Doe        42 pts   │ ← Rank 1 (gold highlight)
│  🥈  [😎] Sarah Lee       38 pts   │ ← Rank 2 (silver)
│  🥉  [😄] Mike Chen       35 pts   │ ← Rank 3 (bronze)
│  4   [😁] You             28 pts   │ ← You (highlighted bg)
│  5   [🙂] Emma Wilson     22 pts   │
│  6   [😊] Tom Harris      18 pts   │
│                                     │
├─────────────────────────────────────┤
│ [🏠]  [🍻]  [🏆]  [👤]             │
└─────────────────────────────────────┘
```

### Profile Screen

```
┌─────────────────────────────────────┐
│  Profile                      [⚙️]  │ ← Settings gear
├─────────────────────────────────────┤
│                                     │
│         ┌─────────┐                 │
│         │   JD    │                 │ ← Avatar (initials)
│         └─────────┘                 │
│                                     │
│       John Doe (@johndoe)           │ ← Name + username
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Total Drinks       │    47   │ │ ← Stats card
│  │  Total Points       │   126   │ │
│  │  Favorite Drink     │  Beer🍺 │ │
│  │  Favorite Venue     │ Murphy's│ │
│  │  Current Streak     │  5 days │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Friends (12)          →      │ │ ← Friends list link
│  └───────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│ [🏠]  [🍻]  [🏆]  [👤]             │
└─────────────────────────────────────┘
```

---

## Animations & Transitions

### Modal Presentation
- **Entry:** Slide up from bottom (300ms, ease-out curve)
- **Exit:** Slide down (250ms, ease-in curve)

### Button Press
- **Scale:** 0.95x when pressed (100ms)
- **Opacity:** 0.7 when pressed (100ms)

### List Item Tap
- **Background:** Fade in gray overlay (150ms)

### Loading States
- **Shimmer:** Subtle gray gradient animation (1.5s loop)
- **Skeleton:** Gray placeholder boxes with rounded corners

---

## Accessibility

### Minimum Touch Targets
- **Buttons:** 44x44 pt (iOS standard)
- **List items:** 48 pt height
- **Icons:** 24x24 pt (visual), 44x44 pt (touch area)

### Color Contrast
- **Text on white:** 4.5:1 ratio (WCAG AA)
- **Primary button text:** White on orange (4.8:1 ratio)

### Dynamic Type Support
- Use `Theme.of(context).textTheme` for scalable text
- Test with iOS Accessibility > Larger Text

---

## Icon System

### Tab Bar Icons
- **Home:** house.fill (SF Symbols)
- **Add:** plus.circle.fill
- **Leaderboard:** chart.bar.fill
- **Profile:** person.circle.fill

### Action Icons
- **Search:** magnifyingglass
- **Settings:** gearshape.fill
- **Close:** xmark
- **Checkmark:** checkmark
- **Bell (notifications):** bell.fill

### Emoji Usage
- **Drinks:** Use emoji in icon grid (🍺🍷🥃🍸🍹)
- **Avatars:** Fallback to initials if no photo

---

## Platform-Specific Notes

### iOS
- Use native `CupertinoDatePicker` for time picker
- Haptic feedback on button press (`HapticFeedback.lightImpact()`)
- Bounce scroll physics (`BouncingScrollPhysics()`)

### Android
- Use Material `showDatePicker` + `showTimePicker`
- Ripple effect on tappable items
- Material Design elevation (card shadows)

---

**End of UI Design Guide**
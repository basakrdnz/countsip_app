# CountSip – Design System v3.1 (Earthy Neutral)

**Brand Identity:** Bold, Sophisticated, Earthy  
**Visual Inspiration:** Premium lounge, coffee tones, high-end materials  
**Design Philosophy:** Warmth meets dark-mode efficiency

---

## 🎨 Color Palette - Dark & Neutral

### Primary Colors
```dart
// lib/core/theme/app_colors.dart

class AppColors {
  // Primary - Earthy Brown (Rich & Neutral)
  static const primary = Color(0xFF714A39);        // Rich brown
  static const primaryLight = Color(0xFF8E6351);   // Lighter shade
  static const primaryDark = Color(0xFF53362A);    // Deeper shade
  
  // Backgrounds - Dark Theme
  static const background = Color(0xFF0A0A0A);     // Almost black
  static const surface = Color(0xFF1A1A1A);        // Dark gray surface
  static const surfaceElevated = Color(0xFF242424); // Elevated surface
  
  // Light Theme Backgrounds
  static const backgroundLight = Color(0xFFF5F5F5); // Light gray
  static const surfaceLight = Color(0xFFFFFFFF);    // White
  static const surfaceElevatedLight = Color(0xFFFAFAFA); // Off-white
  
  // Text - High Contrast
  static const textPrimary = Color(0xFFFFFFFF);     // White (dark mode)
  static const textSecondary = Color(0xFFB0B0B0);   // Light gray
  static const textTertiary = Color(0xFF6B6B6B);    // Medium gray
  
  // Text Light Mode
  static const textPrimaryLight = Color(0xFF1A1A1A); // Almost black
  static const textSecondaryLight = Color(0xFF6B6B6B); // Medium gray
  static const textTertiaryLight = Color(0xFFB0B0B0); // Light gray
  
  // Borders - Subtle
  static const border = Color(0xFF2A2A2A);          // Dark border
  static const borderLight = Color(0xFFE0E0E0);     // Light border
  
  // Status Colors - Muted
  static const success = Color(0xFF4CAF50);         // Green
  static const warning = Color(0xFFFFA726);         // Amber
  static const error = Color(0xFFEF5350);           // Red
  
  // Shadows
  static const shadow = Color(0x40000000);          // 25% black
  static const shadowLight = Color(0x1A000000);     // 10% black
}
```

---

## 🎭 Typography - Clean & Bold

### Font Family
```dart
// Use Inter or SF Pro for clean, modern look
static const fontFamily = 'Inter'; // or 'SF Pro Text'
```

### Text Styles
```dart
class AppTextStyles {
  // Display - Hero text
  static const display = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.2,
    height: 1.0,
  );
  
  // Large Title - Screen headers
  static const largeTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );
  
  // Title 1 - Section headers
  static const title1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  
  // Title 2 - Card titles
  static const title2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );
  
  // Title 3 - Subsection
  static const title3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );
  
  // Body - Regular text
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  // Body Emphasis
  static const bodyEmphasis = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  // Callout
  static const callout = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  
  // Subheadline
  static const subheadline = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  // Footnote
  static const footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );
  
  // Caption
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    letterSpacing: 0.3,
  );
}
```

---

## 📐 Spacing & Layout

### Spacing System
```dart
class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}
```

### Border Radius - Sharp & Modern
```dart
class AppRadius {
  static const none = 0.0;   // Sharp corners
  static const xs = 4.0;     // Minimal rounding
  static const sm = 8.0;     // Small elements
  static const md = 12.0;    // Default
  static const lg = 16.0;    // Cards
  static const xl = 20.0;    // Large elements
  static const xxl = 24.0;   // Modals
  static const round = 999.0; // Pills
}
```

---

## 🧱 Component Styles

### 1. Card - Dark Mode
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(
      color: AppColors.border,
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 20,
        offset: Offset(0, 4),
      ),
    ],
  ),
  padding: EdgeInsets.all(AppSpacing.lg),
  // ... child
)
```

### 2. Primary Button - Bold Orange
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: AppColors.primary.withOpacity(0.5),
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.lg,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
  ),
  onPressed: () {},
  child: Text(
    'Add Drink',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  ),
)
```

### 3. Secondary Button - Ghost
```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    side: BorderSide(
      color: AppColors.border,
      width: 1.5,
    ),
    backgroundColor: Colors.transparent,
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.lg,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
  ),
  onPressed: () {},
  child: Text('Cancel'),
)
```

### 4. Input Field - Dark
```dart
TextField(
  style: AppTextStyles.body,
  decoration: InputDecoration(
    filled: true,
    fillColor: AppColors.surfaceElevated,
    hintText: 'Add a note...',
    hintStyle: AppTextStyles.body.copyWith(
      color: AppColors.textTertiary,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(
        color: AppColors.border,
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(
        color: AppColors.border,
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(
        color: AppColors.primary,
        width: 2,
      ),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
  ),
)
```

### 5. Chip/Tag - Minimal
```dart
Container(
  padding: EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.xs,
  ),
  decoration: BoxDecoration(
    color: AppColors.surfaceElevated,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.all(
      color: AppColors.border,
      width: 1,
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('🍺', style: TextStyle(fontSize: 14)),
      SizedBox(width: AppSpacing.xs),
      Text(
        'Beer',
        style: AppTextStyles.footnote.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
)
```

---

## 🎬 Animations

### Timing
```dart
class AppDuration {
  static const instant = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
}
```

### Curves
```dart
class AppCurves {
  static const easeIn = Curves.easeIn;
  static const easeOut = Curves.easeOut;
  static const easeInOut = Curves.easeInOutCubic;
  static const snap = Curves.easeOutExpo;
}
```

---

## 🖼️ Screen Designs - Updated

### Home Screen (Dark Mode)

```
┌─────────────────────────────────────┐
│  CountSip              [🔔]         │ ← Black background
├─────────────────────────────────────┤
│  #0A0A0A Background                 │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🍺 Beer                       │ │ ← Dark gray card
│  │ John • Murphy's Pub           │ │   #1A1A1A
│  │ 2h ago                        │ │
│  │                               │ │
│  │ +2 pts                        │ │ ← Orange accent
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🍷 Wine                       │ │
│  │ Sarah • Home                  │ │
│  │ 5h ago • +3 pts               │ │
│  └───────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│  [🏠]  [➕]  [🏆]  [👤]            │ ← Dark tab bar
└─────────────────────────────────────┘
```

### Add Drink Sheet

```
┌─────────────────────────────────────┐
│  #1A1A1A Surface                    │
│         [━]                         │
│                                     │
│  Add Drink                    [✕]   │
│                                     │
│  ┌──────────┬──────────┬──────────┐│
│  │   🍺     │   🍷     │   🥃     ││ ← Grid (3x3)
│  │  Beer    │  Wine    │  Whiskey ││   Dark cards
│  │  +2 pts  │  +3 pts  │  +4 pts  ││
│  ├──────────┼──────────┼──────────┤│
│  │   🍸     │   🍹     │   🥃     ││
│  │  Vodka   │ Cocktail │   Shot   ││
│  │  +3 pts  │  +2 pts  │  +2 pts  ││
│  └──────────┴──────────┴──────────┘│
│                                     │
│  Quantity                           │
│  ┌──────────────────────────────┐  │
│  │      [−]    2    [+]         │  │ ← Stepper
│  └──────────────────────────────┘  │
│                                     │
│  Note (optional)                    │
│  ┌──────────────────────────────┐  │
│  │  Great night with friends... │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │      Save Entry              │  │ ← Orange button
│  └──────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

### Leaderboard

```
┌─────────────────────────────────────┐
│  Leaderboard 🏆                     │
│                                     │
│  ┌─────┬─────┬─────┐               │
│  │Week │Month│ All │               │ ← Segmented control
│  └─────┴─────┴─────┘               │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  1  🥇  John Doe     126 pts  │ │ ← Gold highlight
│  │         @johndoe              │ │   (subtle orange glow)
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  2  🥈  Sarah Lee     98 pts  │ │ ← Silver
│  │         @sarahlee             │ │   (light gray glow)
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  3  🥉  Mike Chen     87 pts  │ │ ← Bronze
│  │         @mikechen             │ │   (dark gray glow)
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  4      You          72 pts   │ │ ← You (highlighted)
│  │         @yourname             │ │
│  └───────────────────────────────┘ │
│                                     │
│  5      Emma Wilson    65 pts     │
│  6      Tom Harris     58 pts     │
│                                     │
└─────────────────────────────────────┘
```

### Profile

```
┌─────────────────────────────────────┐
│  Profile                      [⚙️]  │
│                                     │
│         ┌─────────┐                 │
│         │   JD    │                 │ ← Avatar (gray bg)
│         └─────────┘                 │
│                                     │
│       John Doe                      │
│       @johndoe                      │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  This Week                    │ │ ← Stats card
│  │                               │ │
│  │  12 drinks  •  42 points      │ │
│  │                               │ │
│  │  🍺 🍷 🍸 🥃                   │ │ ← Icons
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  All Time Stats               │ │
│  │                               │ │
│  │  Total Drinks       147       │ │
│  │  Total Points       426       │ │
│  │  Best Streak        12 days   │ │
│  │  Favorite           Beer 🍺   │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Friends (24)          →      │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

## 🎨 Visual Elements

### Shadows - Dramatic
```dart
// Card shadow (dark mode)
BoxShadow(
  color: Color(0x40000000), // 25% black
  blurRadius: 20,
  offset: Offset(0, 8),
  spreadRadius: 0,
)

// Button shadow
BoxShadow(
  color: AppColors.primary.withOpacity(0.4),
  blurRadius: 16,
  offset: Offset(0, 6),
)

// Glow effect (selected items)
BoxShadow(
  color: AppColors.primary.withOpacity(0.3),
  blurRadius: 24,
  offset: Offset(0, 0),
  spreadRadius: 2,
)
```

### Gradients - Minimal Use
```dart
// Only for primary button (subtle)
LinearGradient(
  colors: [
    AppColors.primary,
    AppColors.primaryDark,
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

// Background gradient (very subtle)
LinearGradient(
  colors: [
    Color(0xFF0A0A0A),
    Color(0xFF121212),
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
)
```

---

## 🌟 Special Components

### Bottom Navigation - Dark
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    border: Border(
      top: BorderSide(
        color: AppColors.border,
        width: 1,
      ),
    ),
  ),
  child: BottomNavigationBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textTertiary,
    type: BottomNavigationBarType.fixed,
    // ... items
  ),
)
```

### Floating Action Button - Orange
```dart
FloatingActionButton(
  onPressed: () {},
  backgroundColor: AppColors.primary,
  elevation: 8,
  child: Icon(Icons.add, size: 28, color: Colors.white),
)
```

---

## ✨ Final Design Rules

**Color Usage:**
- � **Brown**: ONLY for CTAs, highlights, active states
- ⚫ **Black/Dark Gray**: Backgrounds, surfaces
- ⚪ **White/Light Gray**: Text, borders
- 🚫 **NO pink, coral, pastel colors**

**Typography:**
- Bold weights (600-800) for hierarchy
- High contrast (white on dark)
- Tight letter-spacing for modern look

**Spacing:**
- Generous padding (16-24px)
- Clear visual separation
- Consistent margins

**Gender-Neutral Design:**
- No stereotypical colors
- Universal iconography
- Bold, confident aesthetic
- Professional tone

**Inspiration:**
- Spotify (dark UI)
- Nike apps (bold typography)
- Banking apps (professional)
- Strava (sports tracking)

---

**End of Design System v3.0 - Neutral Edition**
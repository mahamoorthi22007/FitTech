# Silai ✦ — AI Fashion & Tailoring App

A Flutter app for tailors and fashion enthusiasts. Design, stitch, and learn with AI guidance.

## Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `dustyRose` | `#D0A499` | Secondary fills, upload borders |
| `blushLight` | `#F5E2E1` | Card backgrounds, chip fills |
| `terracotta` | `#C9847A` | Primary accent, progress bars |
| `brick` | `#97584E` | Primary buttons, active states |
| `walnut` | `#8F6E4F` | Body text on light fills |
| `espresso` | `#3D2B1F` | Headings, dark text |
| `cream` | `#FDF6F0` | Scaffold background |
| `white` | `#FFFFFF` | Cards, nav bars |

## Project Structure

```
silai_app/
├── lib/
│   ├── main.dart                      ← App entry + MainShell (bottom nav)
│   │
│   ├── theme/
│   │   └── app_theme.dart             ← AppColors + AppTheme
│   │
│   ├── widgets/
│   │   └── shared_widgets.dart        ← Reusable UI components
│   │       ├── SectionLabel
│   │       ├── MiniScrollCard
│   │       ├── FeatureRowCard
│   │       ├── PrimaryButton
│   │       ├── UploadZone
│   │       ├── FilterChipRow
│   │       ├── SelectablePillRow
│   │       ├── SilaiAppBar
│   │       └── StepProgressBar
│   │
│   ├── screens/
│   │   ├── home_screen.dart           ← Hero banner + feature cards
│   │   ├── trending_screen.dart       ← Animated trend grid + filters
│   │   ├── recommend_screen.dart      ← AI style recommender
│   │   ├── blueprint_screen.dart      ← 4-step: upload→measure→blueprint→fit
│   │   ├── stitch_instructions_screen.dart ← Step-by-step stitch guide
│   │   ├── aari_screen.dart           ← Aari & embroidery (3 tabs)
│   │   └── tutorial_screen.dart       ← Learn tailoring tutorials
│   │
│   ├── models/                        ← (extend as needed)
│   └── utils/                         ← (extend as needed)
│
├── assets/
│   ├── fonts/
│   │   ├── PlayfairDisplay-Regular.ttf
│   │   ├── PlayfairDisplay-Medium.ttf
│   │   ├── PlayfairDisplay-SemiBold.ttf
│   │   ├── Lato-Regular.ttf
│   │   ├── Lato-Medium.ttf
│   │   └── Lato-Bold.ttf
│   └── images/
│
└── pubspec.yaml
```

## Screens & Navigation

### Bottom Navigation (5 tabs)
| Tab | Screen | Description |
|-----|--------|-------------|
| Home | `HomeScreen` | Hero, quick access, feature cards |
| Trending | `TrendingScreen` | Animated grid, gender/style filters |
| Stitch (centre) | `BlueprintScreen` | 4-step blueprint wizard |
| Drafts | Placeholder | Saved blueprints (extend) |
| Aari | `AariScreen` | Aari & embroidery with tabs |

### Additional Screens (push navigation)
| Screen | Navigates From |
|--------|---------------|
| `RecommendScreen` | Home → Style AI, Bottom nav |
| `StitchInstructionsScreen` | Blueprint → Get Instructions |
| `TutorialScreen` | Home → Learn Tailoring |

## Key Features Implemented

1. **Home** — Floating animation hero, sparkle effects, feature row cards with AI tags
2. **Trending** — Animated card entrance, scale-on-press, gender + category filters, fabric spotlight
3. **Style Recommender** — Gender selector, dynamic dress picker (Chudithar shows necks/sleeves/styles), fabric AI suggestion, connects to Blueprint
4. **Blueprint Studio** — 4-step progress flow, measurement input form, CustomPainter blueprint diagram, share bottom sheet, 3D avatar (animated), aari suggestions
5. **Stitch Instructions** — Per-step video placeholder + photos, step header navigator, pro tips, next/prev navigation
6. **Aari & Embroidery** — 3-tab layout (Trending, By Dress, Tutorials), difficulty badges
7. **Tutorial** — Learning path banner, filterable tutorial list with ratings, quick guide grid

## Setup

```bash
# 1. Get fonts from Google Fonts
#    Playfair Display + Lato → put in assets/fonts/

# 2. Install dependencies
flutter pub get

# 3. Run
flutter run
```

## Using google_fonts Package (Alternative to local fonts)
If you prefer not to bundle fonts locally, replace the `fontFamily` references in `app_theme.dart`:

```dart
import 'package:google_fonts/google_fonts.dart';

// In AppTheme:
textTheme: GoogleFonts.latoTextTheme(),

// For Playfair headings:
style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w600),
```

And remove the `fonts:` section from pubspec.yaml.

## Extending the App

- **AI Integration**: Connect Claude API or Gemini in `recommend_screen.dart` → replace `_FabricSuggestionCard` with API call
- **Blueprint PDF**: Use `pdf` package to export the `_BlueprintDiagram` CustomPainter to PDF
- **3D Avatar**: Integrate `model_viewer_plus` package for real 3D avatar in `_StepFitCheck`
- **Video Tutorials**: Replace `_VideoPlaceholder` with `video_player` or YouTube embed
- **Image Upload**: `image_picker` is already in pubspec — connect to `UploadZone` buttons

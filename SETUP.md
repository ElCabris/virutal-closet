# Crayoli Closet — Mobile App

> Your closet, curated. — Flutter + Supabase

## Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| State Management | Riverpod |
| Navigation | GoRouter |
| Backend | Supabase (Auth + DB + Storage) |
| AI Suggestions | Anthropic Messages API (model set via `AI_MODEL`) |
| Charts | fl_chart |
| Calendar | table_calendar |

## Screens

| Screen | Description |
|--------|-------------|
| Splash | Logo animation → Auth check |
| Login / Register | Supabase email/password auth |
| My Closet | Grid of garments, filter by category |
| Add Garment | Photo + metadata form |
| Garment Detail | Stats, wear tracking, delete |
| My Outfits | Saved outfits + AI tab |
| AI Suggestions | AI generates outfits from wardrobe |
| Outfit Builder | Select garments → save outfit |
| Calendar | Assign outfits to days with table_calendar |
| Analytics | Pie chart by category, most/least worn |
| Profile | Account info, sign out |

## Setup

### 1. Prerequisites

```bash
# Install Flutter: https://docs.flutter.dev/get-started/install
flutter --version  # requires 3.19+
```

### 2. Configure environment

Copy and fill in your keys:

```bash
cp .env .env.local
```

```dotenv
SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
AI_API_KEY=sk-ant-...
AI_MODEL=<model-id>
```

### 3. Set up Supabase

1. Create a project at https://supabase.com
2. Go to **SQL Editor** and run the migrations in order:
   ```
   supabase/migrations/001_initial_schema.sql
   supabase/migrations/002_garment_images.sql
   ```
3. In **Storage**, verify 3 buckets were created: `garments`, `outfits`, `avatars`
4. Copy your Project URL and anon key into `.env`

### 4. Get an AI API key

1. Go to https://console.anthropic.com
2. Create an API key
3. Add it to `.env` as `AI_API_KEY`
4. Set `AI_MODEL` in `.env` to the ID of the model you want to use (a small, fast model is enough for outfit suggestions)

### 5. Install dependencies & run

```bash
flutter pub get
flutter run
```

### 6. (Optional) Add Playfair Display fonts

Download from Google Fonts and place in `assets/fonts/`:
- `PlayfairDisplay-Regular.ttf`
- `PlayfairDisplay-Bold.ttf`
- `PlayfairDisplay-Italic.ttf`

Or remove the font declarations from `pubspec.yaml` to use the fallback.

## Project Structure

```
lib/
├── core/
│   ├── constants/   # App constants, categories, colors
│   ├── theme/       # Dark theme, color palette
│   └── utils/       # Date formatters, color helpers
├── data/
│   ├── datasources/ # AI service (Anthropic API)
│   ├── models/      # Garment, Outfit, CalendarEntry
│   └── repositories/# Supabase CRUD for each entity
├── presentation/
│   ├── providers/   # Riverpod providers (central)
│   ├── screens/     # All screens by feature
│   └── widgets/     # Reusable UI components
├── app.dart         # GoRouter + MaterialApp
└── main.dart        # Supabase init + entry point
```

## AI Outfit Suggestions

The AI tab in Outfits uses the model configured in `AI_MODEL` to analyze your wardrobe and generate outfit suggestions with:
- Outfit name and description
- Specific garments from your closet
- Styling tip
- Occasion label

Suggestions are generated fresh each time (no caching) and can be saved directly as outfits.

## Building for release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ipa
```

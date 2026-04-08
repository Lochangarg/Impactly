# Impactly - Flutter Folder Structure

## 📁 Root Structure
- `.env`: **LOCAL ONLY!** Store your sensitive Supabase & Parse keys here.
- `.env.example`: Template for environment variables (Supabase + Parse).
- `.gitignore`: Configured to exclude `.env`, build outputs, and generated files.
- `pubspec.yaml`: Project dependencies including `supabase_flutter`, `flutter_dotenv`, etc.
- `README.md`: Full project documentation with setup instructions.
- `CONTRIBUTING.md`: Branching, commit, and PR guidelines.
- `LICENSE`: MIT License file.

## 📂 Documentation (`docs/`)
- `Impactly_Project_Report.md`: Full project report in Markdown.
- `SUPABASE_MIGRATION_PLAN.md`: Migration SQL reference for Supabase tables.
- `Commands I Runned On Supabase SQL CLI.md`: SQL commands executed during setup.
- `MESSAGING_SCHEMA_FIX.sql`: Messaging schema migration fix.
- `MiroDesign application.pdf`: High-fidelity wireframes and design mockups.
- `*.docx/*.pdf`: Academic report files.

## 📂 Assets (`assets/`)
- `icons/`: App icons (e.g., `Impactly_app_icon.png`).
- `screenshots/`: App UI screenshots for documentation.

## 📂 Core Layer (`lib/core/`)
- `config/`: Configuration files (e.g., `env.dart` — Supabase URL & Anon Key).
- `constants/`: Global constants (e.g., `app_constants.dart`).
- `models/`: Shared data models.
- `navigation/`: MainScreen with BottomNavigationBar.
- `providers/`: State providers.
- `services/`: Backend services.
- `theme/`: Global styling (e.g., `app_theme.dart`).
- `utils/`: Common helpers & extensions.

## 📂 Feature Layer (`lib/features/`)
Each feature follows a **feature-first** approach:
- `auth/`: Login, Sign-up, Forgot/Reset Password.
- `chat/`: Direct messaging.
- `events/`: Event management and discovery.
- `feed/`: Community activity feed.
- `home/`: Home dashboard.
- `language/`: Language selection.
- `leaderboard/`: Points ranking.
- `onboarding/`: Initial setup.
- `profile/`: User profile and settings.
- `social/`: User search and friendships.
- `update/`: Update mechanism.

## 📂 Localisation (`lib/l10n/`)
- `app_en.arb`, `app_hi.arb`: Localised strings for English and Hindi.

## ⚙️ Initialization (`lib/main.dart`)
Loads environment variables and initializes Supabase before the application starts.
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  runApp(const MyApp());
}
```

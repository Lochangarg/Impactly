# Impactly - Flutter Folder Structure

## 📁 Root Structure
- `.env`: **LOCAL ONLY!** Store your sensitive Parse keys here.
- `.env.example`: Template for environment variables.
- `.gitignore`: Configured to exclude `.env` from being pushed.
- `pubspec.yaml`: Modified to include `flutter_dotenv` and the `.env` asset.

## 📂 Core Layer (`lib/core/`)
- `config/`: Configuration files (e.g., `env.dart`).
- `constants/`: Global constants (e.g., `app_constants.dart`).
- `services/`: Global services (e.g., `parse_service.dart`).
- `theme/`: Global styling (e.g., `app_theme.dart`).
- `utils/`: Common helpers & extensions.
- `widgets/`: Globally shared UI components.

## 📂 Feature Layer (`lib/features/`)
Each feature follows a **feature-first** approach:
- `auth/`: Login, Sign-up, Logout, and authentication-related logic.
- `feed/`: Community feed, post creation, and like/comment interactions.
- `events/`: Event management, browsing, and participation.
- `profile/`: User profile updates and personal settings.
- `notifications/`: Infrastructure and UI for app notifications.

## 📂 Routing (`lib/routes/`)
- `app_routes.dart`: Centralized route definitions used in `MaterialApp`.

## ⚙️ Initialization (`lib/main.dart`)
Loads environment variables and initializes Parse Server before the application starts.
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Parse().initialize(
    Env.appId,
    Env.serverUrl,
    clientKey: Env.clientKey,
    autoSendSessionId: true,
  );
  runApp(MyApp());
}
```

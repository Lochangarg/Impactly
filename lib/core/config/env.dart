import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get updateUrl => dotenv.env['APP_UPDATE_URL'] ?? 'https://raw.githubusercontent.com/Lochangarg/Impactly/refs/heads/main/update.json';
}

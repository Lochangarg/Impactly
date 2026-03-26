import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get appId => dotenv.env['PARSE_APP_ID'] ?? '';
  static String get clientKey => dotenv.env['PARSE_CLIENT_KEY'] ?? '';
  static String get serverUrl => dotenv.env['PARSE_SERVER_URL'] ?? 'https://parseapi.back4app.com';
}

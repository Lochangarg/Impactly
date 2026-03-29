import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static final _translator = GoogleTranslator();
  static final Map<String, String> _cache = {};

  static Future<String> translate(String text, String targetLanguageCode) async {
    if (text.isEmpty) return '';
    if (targetLanguageCode == 'en') return text; // Assume source is often English
    
    final key = '$text-$targetLanguageCode';
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      final translation = await _translator.translate(text, to: targetLanguageCode);
      _cache[key] = translation.text;
      return translation.text;
    } catch (e) {
      print('Translation Error: $e');
      return text; // Fallback to original
    }
  }

  static bool isHindi() {
    // This is a simple helper, usually you'd check the app locale
    // But for this purpose, let's assume we can check if target is hi
    return true; 
  }
}

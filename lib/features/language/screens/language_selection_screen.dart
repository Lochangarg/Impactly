import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isFromProfile;
  const LanguageSelectionScreen({super.key, this.isFromProfile = false});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedLocale = context.read<LocaleProvider>().locale ?? const Locale('en');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isFromProfile)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
              const SizedBox(height: 20),
              Text(
                l10n.select_language,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.experience_impactly,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 48),
              _buildLanguageOption(
                title: "English",
                subtitle: "Default language",
                locale: const Locale('en'),
                icon: "🇺🇸",
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                title: "हिंदी",
                subtitle: "Hindi (हिन्दी)",
                locale: const Locale('hi'),
                icon: "🇮🇳",
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedLocale == null ? null : () {
                    context.read<LocaleProvider>().setLocale(_selectedLocale!);
                    if (widget.isFromProfile) {
                      Navigator.pop(context);
                    } else {
                      // Initial entry, but main.dart will handle navigation based on provider state
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.continue_text,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required Locale locale,
    required String icon,
  }) {
    final isSelected = _selectedLocale?.languageCode == locale.languageCode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLocale = locale;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF1E1B4B) : const Color(0xFF111827),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF6366F1)),
          ],
        ),
      ),
    );
  }
}

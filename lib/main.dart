import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/config/env.dart';
import 'features/auth/login_screen.dart';
import 'core/navigation/main_screen.dart';
import 'core/providers/event_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'features/language/screens/language_selection_screen.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/update_service.dart';
import 'features/home/widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  await Parse().initialize(
    Env.appId,
    Env.serverUrl,
    clientKey: Env.clientKey,
    autoSendSessionId: true,
  );

  final currentUser = await ParseUser.currentUser() as ParseUser?;
  final bool isLoggedIn = currentUser != null;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkUpdate();
    if (widget.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<EventProvider>().loadJoinedEvents();
      });
    }
  }

  Future<void> _checkUpdate() async {
    final updateService = UpdateService(updateConfigUrl: Env.updateUrl);
    final update = await updateService.checkForUpdate();
    if (update != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: !update.forceUpdate,
        builder: (context) => UpdateDialog(update: update),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocaleProvider, ThemeProvider>(
      builder: (context, localeProvider, themeProvider, _) {
        return MaterialApp(
          title: 'Impactly',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
          ],
          home: _getHomeScreen(localeProvider),
          routes: AppRoutes.routes,
        );
      },
    );
  }

  Widget _getHomeScreen(LocaleProvider localeProvider) {
    if (!localeProvider.isLocaleSet) {
      return const LanguageSelectionScreen();
    }
    return widget.isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}

import 'package:flutter/material.dart';
import '../../features/home/home_screen.dart';
import '../../features/events/events_screen.dart';
import '../../features/feed/feed_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/social/user_search_screen.dart';
import '../../l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static _MainScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainScreenState>();

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _selectedCategory;

  void setTab(int index, {String? category}) {
    setState(() {
      _selectedIndex = index;
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> screens = [
      HomeScreen(onNavigate: (index, {category}) => setTab(index, category: category)),
      const UserSearchScreen(),
      EventsScreen(key: ValueKey(_selectedCategory), initialCategory: _selectedCategory),
      const FeedScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setTab(index),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home_filled), label: l10n.home),
          BottomNavigationBarItem(icon: const Icon(Icons.search), activeIcon: const Icon(Icons.search), label: l10n.search_users),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_month_outlined), activeIcon: const Icon(Icons.calendar_month), label: l10n.events),
          BottomNavigationBarItem(icon: const Icon(Icons.dynamic_feed_outlined), activeIcon: const Icon(Icons.dynamic_feed), label: l10n.feed),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: l10n.profile),
        ],
      ),
    );
  }
}

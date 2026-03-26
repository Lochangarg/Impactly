import 'package:flutter/material.dart';
import '../../features/home/home_screen.dart';
import '../../features/events/events_screen.dart';
import '../../features/feed/feed_screen.dart';
import '../../features/profile/profile_screen.dart';

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
    // Re-initialize screens to pick up potential category changes
    final List<Widget> screens = [
      HomeScreen(onNavigate: (index, {category}) => setTab(index, category: category)),
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
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: const Color(0xFF9CA3AF),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.dynamic_feed_outlined), activeIcon: Icon(Icons.dynamic_feed), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

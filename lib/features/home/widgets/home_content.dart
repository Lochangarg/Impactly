import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'points_card.dart';
import 'event_card.dart';
import 'category_icon.dart';
import '../../../core/services/parse_service.dart';
import '../../events/event_details_screen.dart';
import '../../../core/providers/event_provider.dart';
import '../../leaderboard/leaderboard_screen.dart';

class HomeContent extends StatefulWidget {
  final Function(int, {String? category})? onNavigate;
  const HomeContent({super.key, this.onNavigate});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<Map<String, dynamic>> _homeData;

  @override
  void initState() {
    super.initState();
    _homeData = _fetchHomeData();
  }

   Future<Map<String, dynamic>> _fetchHomeData() async {
    final user = await ParseService.getCurrentUser();
    // Fetch all events (sorted by createdAt by default in fetchEvents)
    final events = await ParseService.fetchEvents();
    return {'user': user, 'events': events};
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

    return FutureBuilder<Map<String, dynamic>>(
      future: _homeData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
        }

        final user = snapshot.data?['user'] as ParseUser?;
        final events = snapshot.data?['events'] as List<ParseObject>? ?? [];
        
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => setState(() => _homeData = _fetchHomeData()),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Banner
                  _buildBanner(user?.get<String>('fullName') ?? 'User'),
                  const SizedBox(height: 32),

                  // Points Card
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen())),
                    child: PointsCard(points: user?.get<int>('points') ?? 0, level: user?.get<int>('level') ?? 1),
                  ),
                  const SizedBox(height: 40),

                  // Categories
                  const Text('Explore Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CategoryIcon(label: 'Cleaning', icon: Icons.cleaning_services, color: const Color(0xFF10B981), 
                          onTap: () => widget.onNavigate?.call(1, category: 'Cleaning')),
                      CategoryIcon(label: 'Workshops', icon: Icons.school, color: const Color(0xFF3B82F6),
                          onTap: () => widget.onNavigate?.call(1, category: 'Workshops')),
                      CategoryIcon(label: 'Social', icon: Icons.volunteer_activism, color: const Color(0xFFF59E0B),
                          onTap: () => widget.onNavigate?.call(1, category: 'Social')),
                      CategoryIcon(label: 'Music', icon: Icons.music_note, color: const Color(0xFFEC4899),
                          onTap: () => widget.onNavigate?.call(1, category: 'Music')),
                    ],
                  ),
                  const SizedBox(height: 40),

                   // Recently Added Events
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recently Added Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () => widget.onNavigate?.call(1), child: const Text('See All')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (events.isEmpty) 
                    const Text('No events added yet', style: TextStyle(color: Colors.grey))
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: events.map((e) {
                          final date = e.get<DateTime>('date');
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsScreen(eventId: e.objectId!))),
                            child: EventCard(
                              title: e.get<String>('title') ?? 'Untitled',
                              date: date != null ? DateFormat('MMM d, hh:mm a').format(date) : 'No date',
                              location: e.get<String>('location') ?? 'Virtual',
                              imageUrl: '',
                              isOwner: e.get<ParseObject>('createdBy')?.objectId == user?.objectId,
                              isJoined: eventProvider.isUserJoined(e.objectId),
                              onJoin: () => eventProvider.joinEvent(e),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBanner(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hi, ${name.split(' ')[0]}! 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Ready to make an impact?', style: TextStyle(color: Colors.grey)),
        ]),
        const Icon(Icons.notifications_outlined),
      ],
    );
  }
}

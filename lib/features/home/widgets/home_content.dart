import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'points_card.dart';
import 'event_card.dart';
import 'category_icon.dart';
import '../../events/event_details_screen.dart';
import '../../../core/providers/event_provider.dart';
import '../../leaderboard/leaderboard_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../chat/direct_messages_screen.dart';
import '../notifications_screen.dart';

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
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) return {'user': null, 'events': []};
    
    final user = await SupabaseService.fetchUserDetails(me.id);
    final events = await SupabaseService.fetchEvents();
    final notifications = await SupabaseService.fetchNotifications(onlyPending: true);
    
    // Auto-translate titles if Hindi
    final locale = Localizations.maybeLocaleOf(context)?.toString() ?? 'en';
    if (locale == 'hi') {
      for (var e in events) {
        final title = e['title'] ?? '';
        final location = e['location'] ?? '';
        
        final translatedTitle = await TranslationService.translate(title, 'hi');
        final translatedLocation = await TranslationService.translate(location, 'hi');
        
        e['title'] = translatedTitle;
        e['location'] = translatedLocation;
      }
    }

    return {
      'user': user, 
      'events': events, 
      'hasNotifications': notifications.isNotEmpty
    };
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<Map<String, dynamic>>(
      future: _homeData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
        }

        final user = snapshot.data?['user'] as Map<String, dynamic>?;
        final events = snapshot.data?['events'] as List<Map<String, dynamic>>? ?? [];
        
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => setState(() => _homeData = _fetchHomeData()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Welcome Banner
                  _buildBanner(user?['full_name'] ?? 'User', l10n, snapshot.data?['hasNotifications'] ?? false),
                  const SizedBox(height: 32),

                  // Points Card
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen())),
                    child: PointsCard(points: user?['points'] ?? 0, level: user?['level'] ?? 1),
                  ),
                  const SizedBox(height: 40),

                  // Categories
                  Text(l10n.explore_categories, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CategoryIcon(label: l10n.cleaning, icon: Icons.cleaning_services, color: const Color(0xFF10B981), 
                          onTap: () => widget.onNavigate?.call(2, category: 'Cleaning')),
                      CategoryIcon(label: l10n.workshops, icon: Icons.school, color: const Color(0xFF3B82F6),
                          onTap: () => widget.onNavigate?.call(2, category: 'Workshops')),
                      CategoryIcon(label: l10n.social, icon: Icons.volunteer_activism, color: const Color(0xFFF59E0B),
                          onTap: () => widget.onNavigate?.call(2, category: 'Social')),
                      CategoryIcon(label: l10n.music, icon: Icons.music_note, color: const Color(0xFFEC4899),
                          onTap: () => widget.onNavigate?.call(2, category: 'Music')),
                    ],
                  ),
                  const SizedBox(height: 40),

                   // Recently Added Events
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.recently_added_events, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () => widget.onNavigate?.call(2), child: Text(l10n.see_all)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (events.isEmpty) 
                    Text(l10n.no_events_added, style: const TextStyle(color: Colors.grey))
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: events.map((e) {
                          final dateStr = e['date'];
                          final date = dateStr != null ? DateTime.parse(dateStr) : null;
                          final eventId = e['id'].toString();
                          
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsScreen(eventId: eventId))),
                            child: EventCard(
                              title: e['title'] ?? 'Untitled',
                              date: date != null ? DateFormat('MMM d, hh:mm a', Localizations.localeOf(context).toString()).format(date) : l10n.no_date,
                              location: e['location'] ?? 'Virtual',
                              imageUrl: '',
                              isOwner: e['created_by'] == user?['id'],
                              isJoined: eventProvider.isUserJoined(eventId),
                              onJoin: () => eventProvider.joinEvent(eventId, e['points'] ?? 0),
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

  Widget _buildBanner(String name, AppLocalizations l10n, bool hasNotifications) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.hi_user(name.split(' ')[0]), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(l10n.ready_to_impact, style: const TextStyle(color: Colors.grey)),
        ]),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.message_outlined),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectMessagesScreen()));
              },
            ),
            Badge(
              isLabelVisible: hasNotifications,
              backgroundColor: Colors.red,
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  ).then((_) => setState(() => _homeData = _fetchHomeData()));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

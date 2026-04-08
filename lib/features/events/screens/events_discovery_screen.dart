import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/event_card.dart';
import '../widgets/filter_chips.dart';
import '../../../core/providers/event_provider.dart';
import '../event_details_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/supabase_service.dart';

class EventsDiscoveryScreen extends StatefulWidget {
  const EventsDiscoveryScreen({super.key});

  @override
  State<EventsDiscoveryScreen> createState() => _EventsDiscoveryScreenState();
}

class _EventsDiscoveryScreenState extends State<EventsDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filters = ['All', 'Cleaning', 'Workshops', 'Volunteering', 'Music', 'Social'];
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final details = await SupabaseService.fetchUserDetails(user.id);
      if (mounted) {
        setState(() {
          _currentUser = details;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchEvents() async {
    return await SupabaseService.fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l10n.search_impact_events,
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 20),
              child: FilterChips(
                filters: _filters,
                onSelected: (filter) {},
              ),
            ),

            // Vertical List of Event Cards
            Expanded(
              child: eventProvider.isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
              : FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text(l10n.no_events_found));
                  }

                  final List<Map<String, dynamic>> events = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final eventObject = events[index];
                      final eventId = eventObject['id'].toString();
                       return GestureDetector(
                         onTap: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (_) => EventDetailsScreen(eventId: eventId),
                             ),
                           );
                         },
                         child: EventDiscoveryCard(
                           eventObject: eventObject,
                           currentUser: _currentUser,
                           isJoined: eventProvider.isUserJoined(eventId),
                           onJoin: () => eventProvider.joinEvent(eventObject),
                         ),
                       );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

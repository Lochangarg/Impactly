import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/event_card.dart';
import '../widgets/filter_chips.dart';
import '../../../core/providers/event_provider.dart';
import '../event_details_screen.dart';

class EventsDiscoveryScreen extends StatefulWidget {
  const EventsDiscoveryScreen({super.key});

  @override
  State<EventsDiscoveryScreen> createState() => _EventsDiscoveryScreenState();
}

class _EventsDiscoveryScreenState extends State<EventsDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filters = ['All', 'Cleaning', 'Workshops', 'Volunteering', 'Music', 'Social'];
  ParseUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      await user.fetch();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    }
  }

  Future<List<ParseObject>> _fetchEvents() async {
    final QueryBuilder<ParseObject> queryBuilder =
        QueryBuilder<ParseObject>(ParseObject('Events'))
          ..includeObject(['createdBy']) 
          ..orderByDescending('createdAt');

    final ParseResponse apiResponse = await queryBuilder.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

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
                        decoration: const InputDecoration(
                          hintText: 'Search impact events...',
                          hintStyle: TextStyle(
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
              : FutureBuilder<List<ParseObject>>(
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
                    return const Center(child: Text('No events found'));
                  }

                  final List<ParseObject> events = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final eventObject = events[index];
                       return GestureDetector(
                         onTap: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (_) => EventDetailsScreen(eventId: eventObject.objectId!),
                             ),
                           );
                         },
                         child: EventDiscoveryCard(
                           eventObject: eventObject,
                           currentUser: _currentUser,
                           isJoined: eventProvider.isUserJoined(eventObject.objectId),
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

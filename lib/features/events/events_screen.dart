import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'widgets/event_list_item.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import '../../core/services/parse_service.dart';
import '../../core/providers/event_provider.dart';

class EventsScreen extends StatefulWidget {
  final String? initialCategory;
  const EventsScreen({super.key, this.initialCategory});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late String _selectedCategory;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final List<String> _filters = ['All', 'Cleaning', 'Workshops', 'Volunteering', 'Music', 'Social'];
   bool _isActionLoading = false;
   String? _loadingEventId;
   ParseUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ParseObject>> _getData() async {
    return await ParseService.fetchEvents(category: _selectedCategory, searchQuery: _searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Discover Events', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedCategory == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = filter);
                    },
                    backgroundColor: const Color(0xFFF3F4F6),
                    selectedColor: const Color(0xFF6366F1).withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? const Color(0xFF6366F1) : Colors.transparent)),
                  ),
                );
              }).toList(),
            ),
          ),

          // Events List
          Expanded(
            child: FutureBuilder<List<ParseObject>>(
              future: _getData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
                }

                final events = snapshot.data ?? [];

                if (events.isEmpty) {
                  return const Center(child: Text('No events found', style: TextStyle(color: Color(0xFF6B7280))));
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final dateObj = event.get<DateTime>('date');
                      final dateStr = dateObj != null ? DateFormat('EEE, MMM d • hh:mm a').format(dateObj) : 'No date';

                      final isOwner = event.get<ParseObject>('createdBy')?.objectId == _currentUser?.objectId;
                      
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsScreen(eventId: event.objectId!))),
                        child: EventListItem(
                          title: event.get<String>('title') ?? 'Untitled',
                          date: dateStr,
                          location: event.get<String>('location') ?? 'Virtual',
                          points: event.get<int>('points') ?? 0,
                          category: event.get<String>('category') ?? 'General',
                          isLoading: _loadingEventId == event.objectId,
                          isOwner: isOwner,
                          isJoined: eventProvider.isUserJoined(event.objectId),
                           onJoin: () => eventProvider.joinEvent(event),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEventScreen()));
          if (result == true) setState(() {});
        },
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Event', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

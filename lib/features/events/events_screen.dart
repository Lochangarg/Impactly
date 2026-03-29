import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'widgets/event_list_item.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import '../../core/services/parse_service.dart';
import '../../core/providers/event_provider.dart';
import '../../core/services/translation_service.dart';
import '../../l10n/app_localizations.dart';

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
   bool _autoTranslate = true;

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

    final l10n = AppLocalizations.of(context)!;
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.discover_events, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_autoTranslate ? Icons.translate : Icons.g_translate_outlined, 
              color: const Color(0xFF6366F1),
            ),
            tooltip: 'Toggle Translation',
            onPressed: () => setState(() => _autoTranslate = !_autoTranslate),
          ),
        ],
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
                hintText: l10n.search_events,
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
                final String filterLabel = () {
                  switch (filter) {
                    case 'All': return l10n.all;
                    case 'Cleaning': return l10n.cleaning;
                    case 'Workshops': return l10n.workshops;
                    case 'Volunteering': return l10n.volunteering;
                    case 'Music': return l10n.music;
                    case 'Social': return l10n.social;
                    default: return filter;
                  }
                }();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filterLabel),
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

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  color: const Color(0xFF6366F1),
                  child: events.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.5,
                          alignment: Alignment.center,
                          child: Text(l10n.no_events_found, style: const TextStyle(color: Color(0xFF6B7280))),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                      final event = events[index];
                      final dateObj = event.get<DateTime>('date');
                      final locale = Localizations.localeOf(context).toString();
                      final dateStr = dateObj != null ? DateFormat('EEE, MMM d • hh:mm a', locale).format(dateObj) : l10n.no_date;

                      final isOwner = event.get<ParseObject>('createdBy')?.objectId == _currentUser?.objectId;
                      
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsScreen(eventId: event.objectId!))),
                        child: FutureBuilder<List<String>>(
                          future: Future.wait([
                            _autoTranslate && isHindi ? TranslationService.translate(event.get<String>('title') ?? 'Untitled', 'hi') : Future.value(event.get<String>('title') ?? 'Untitled'),
                            _autoTranslate && isHindi ? TranslationService.translate(event.get<String>('location') ?? 'Virtual', 'hi') : Future.value(event.get<String>('location') ?? 'Virtual'),
                          ]),
                          builder: (context, transSnapshot) {
                            final translatedTitle = transSnapshot.data?[0] ?? event.get<String>('title') ?? 'Untitled';
                            final translatedLocation = transSnapshot.data?[1] ?? event.get<String>('location') ?? 'Virtual';

                            return EventListItem(
                              title: translatedTitle,
                              date: dateStr,
                              location: translatedLocation,
                              points: event.get<int>('points') ?? 0,
                              category: event.get<String>('category') ?? 'General',
                              isLoading: _loadingEventId == event.objectId,
                              isOwner: isOwner,
                              isJoined: eventProvider.isUserJoined(event.objectId),
                               onJoin: () => eventProvider.joinEvent(event),
                            );
                          }
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
        label: Text(l10n.create_event, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/event_provider.dart';
import '../../core/constants/app_constants.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  ParseObject? _event;
  bool _isLoading = true;
  bool _isActionLoading = false;
  ParseUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = await ParseUser.currentUser() as ParseUser?;
      
      // 6. Fix Navigation Issue: FETCH event again
      final query = QueryBuilder<ParseObject>(ParseObject('Events'))
        ..whereEqualTo('objectId', widget.eventId)
        ..includeObject(['createdBy']);
      
      final response = await query.query();
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        _event = response.results!.first as ParseObject;
      }
    } catch (e) {
      debugPrint("Error loading event: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onJoinEvent() async {
    if (_event == null) return;
    setState(() => _isActionLoading = true);
    
    // 3. Update state immediately via Provider
    await context.read<EventProvider>().joinEvent(_event!);
    
    if (mounted) {
      setState(() => _isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Joined successfully! 🚀"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_event == null) {
      return const Scaffold(body: Center(child: Text("Event not found")));
    }

    final eventProvider = context.watch<EventProvider>();
    final title = _event!.get<String>('title') ?? 'Untitled';
    final description = _event!.get<String>('description') ?? 'No description provided.';
    final location = _event!.get<String>('location') ?? 'Virtual';
    final points = _event!.get<int>('points') ?? 0;
    final category = _event!.get<String>('category') ?? 'General';
    final dateObj = _event!.get<DateTime>('date');
    final dateStr = dateObj != null ? DateFormat('EEEE, MMM d, yyyy • hh:mm a').format(dateObj) : 'No date';
    final creator = _event!.get<ParseObject>('createdBy');
    final creatorName = creator?.get<String>('fullName') ?? 'Organizer';
    
    // 5. Fix Button Logic
    final isOwner = creator?.objectId == _currentUser?.objectId;
    final isJoined = eventProvider.isUserJoined(_event!.objectId);

    print("DEBUG: Joined IDs: ${eventProvider.joinedEventIds}");
    print("DEBUG: Current Event: ${_event!.objectId}");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: const Color(0xFFEEF2FF),
              child: const Center(child: Icon(Icons.event_available, size: 80, color: Color(0xFF6366F1))),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(category, style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.calendar_month_outlined, 'When', dateStr),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.location_on_outlined, 'Location', location),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.stars_outlined, 'Reward', '+$points Points'),
                  const Divider(height: 48, color: Color(0xFFF3F4F6), thickness: 1.5),
                  const Text('About this Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(description, style: const TextStyle(color: Color(0xFF4B5563), height: 1.6, fontSize: 15)),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const CircleAvatar(backgroundColor: Color(0xFF6366F1), child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Organized by', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                          Text(creatorName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (isOwner || isJoined || _isActionLoading) ? null : _onJoinEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: (isOwner || isJoined) ? Colors.grey.shade300 : const Color(0xFF6366F1),
              foregroundColor: (isOwner || isJoined) ? Colors.grey.shade600 : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isActionLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  isOwner ? AppConstants.ownerLabel : (isJoined ? AppConstants.joinedLabel : AppConstants.joinEventLabel),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          ],
        ),
      ],
    );
  }
}

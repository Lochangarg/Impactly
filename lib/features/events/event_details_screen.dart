import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/event_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';

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

  void _onJoinEvent(AppLocalizations l10n) async {
    if (_event == null) return;
    setState(() => _isActionLoading = true);
    
    await context.read<EventProvider>().joinEvent(_event!);
    
    if (mounted) {
      setState(() => _isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.joined_successfully), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_event == null) {
      return Scaffold(body: Center(child: Text(l10n.event_not_found)));
    }

    final eventProvider = context.watch<EventProvider>();
    final title = _event!.get<String>('title') ?? l10n.untitled;
    final description = _event!.get<String>('description') ?? '';
    final location = _event!.get<String>('location') ?? l10n.location;
    final points = _event!.get<int>('points') ?? 0;
    final category = _event!.get<String>('category') ?? 'General';
    final dateObj = _event!.get<DateTime>('date');
    final dateStr = dateObj != null ? DateFormat('EEEE, MMM d, yyyy • hh:mm a').format(dateObj) : l10n.no_date;
    final creator = _event!.get<ParseObject>('createdBy');
    final creatorName = creator?.get<String>('fullName') ?? 'Organizer';
    
    final isOwner = creator?.objectId == _currentUser?.objectId;
    final isJoined = eventProvider.isUserJoined(_event!.objectId);

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
                  _buildInfoRow(Icons.calendar_month_outlined, l10n.when, dateStr),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.location_on_outlined, l10n.location, location),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.stars_outlined, l10n.reward, '+$points ${l10n.points_unit}'),
                  const Divider(height: 48, color: Color(0xFFF3F4F6), thickness: 1.5),
                  Text(l10n.about_event, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          Text(l10n.organized_by, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
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
            onPressed: (isOwner || isJoined || _isActionLoading) ? null : () => _onJoinEvent(l10n),
            style: ElevatedButton.styleFrom(
              backgroundColor: (isOwner || isJoined) ? Colors.grey.shade300 : const Color(0xFF6366F1),
              foregroundColor: (isOwner || isJoined) ? Colors.grey.shade600 : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isActionLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  isOwner ? l10n.your_event : (isJoined ? l10n.joined : l10n.join_event),
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

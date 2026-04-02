import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/event_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import 'event_award_approval_screen.dart';

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
  bool _isAwardPending = false;

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
        
        // Check if user already finished but pending award
        if (_currentUser != null) {
          final joinQuery = QueryBuilder<ParseObject>(ParseObject('EventParticipants'))
            ..whereEqualTo('event', _event)
            ..whereEqualTo('user', _currentUser)
            ..whereEqualTo('status', 'award_pending');
          final joinResp = await joinQuery.query();
          _isAwardPending = joinResp.success && joinResp.results != null && joinResp.results!.isNotEmpty;
        }
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

  void _onFinishEvent() async {
    if (_event == null || _currentUser == null) return;
    setState(() => _isActionLoading = true);
    
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('EventParticipants'))
        ..whereEqualTo('event', _event)
        ..whereEqualTo('user', _currentUser);
      
      final resp = await query.query();
      if (resp.success && resp.results != null && resp.results!.isNotEmpty) {
        final participant = resp.results!.first as ParseObject;
        participant.set('status', 'award_pending');
        await participant.save();
        setState(() {
          _isAwardPending = true;
          _isActionLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isActionLoading = false);
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
    final isOver = dateObj != null && dateObj.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isOwner)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventAwardApprovalScreen(event: _event!)),
                );
              },
              icon: const Icon(Icons.check_circle_outline, color: Color(0xFF6366F1)),
              label: const Text('Approvals', style: TextStyle(color: Color(0xFF6366F1))),
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                  Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 24),
                  _buildInfoRow(context, Icons.calendar_month_outlined, l10n.when, dateStr),
                  const SizedBox(height: 16),
                  _buildInfoRow(context, Icons.location_on_outlined, l10n.location, location),
                  const SizedBox(height: 16),
                  _buildInfoRow(context, Icons.stars_outlined, l10n.reward, '+$points ${l10n.points_unit}'),
                  Divider(height: 48, color: Theme.of(context).dividerColor.withOpacity(0.5), thickness: 1.5),
                  Text(l10n.about_event, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  Text(description, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.6, fontSize: 15)),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const CircleAvatar(backgroundColor: Color(0xFF6366F1), child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.organized_by, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                          Text(creatorName, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (isOwner || _isAwardPending || _isActionLoading || (isOver && !isJoined)) ? null : (isJoined ? _onFinishEvent : () => _onJoinEvent(l10n)),
            style: ElevatedButton.styleFrom(
              backgroundColor: (isOwner || _isAwardPending || (isOver && !isJoined)) ? Theme.of(context).dividerColor : const Color(0xFF6366F1),
              foregroundColor: (isOwner || _isAwardPending || (isOver && !isJoined)) ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isActionLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  isOwner ? l10n.your_event : (_isAwardPending ? 'Award Pending' : (isJoined ? 'Mark as Done' : (isOver ? 'Event Over' : l10n.join_event))),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
            Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ],
    );
  }
}

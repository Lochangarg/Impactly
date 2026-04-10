import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/event_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../l10n/app_localizations.dart';
import 'event_award_approval_screen.dart';
import 'create_event_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/translation_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  Map<String, dynamic>? _event;
  bool _isLoading = true;
  bool _isActionLoading = false;
  User? _currentUser;
  bool _isAwardPending = false;
  bool _autoTranslate = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = Supabase.instance.client.auth.currentUser;
      
      final response = await Supabase.instance.client
          .from('events')
          .select('*, profiles:created_by(*)')
          .eq('id', widget.eventId)
          .single();
      
      if (response != null) {
        _event = response;
        
        // Check if user already finished but pending award
        if (_currentUser != null) {
          final joinResponse = await Supabase.instance.client
            .from('user_events')
            .select('status')
            .eq('event_id', widget.eventId)
            .eq('user_id', _currentUser!.id)
            .maybeSingle();

          if (joinResponse != null) {
             _isAwardPending = joinResponse['status'] == 'award_pending';
          }
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
    
    final int points = _event!['points'] ?? 0;
    final error = await context.read<EventProvider>().joinEvent(widget.eventId, points);
    
    if (mounted) {
      setState(() => _isActionLoading = false);
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.joined_successfully), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onFinishEvent() async {
    if (_event == null || _currentUser == null) return;
    setState(() => _isActionLoading = true);
    
    try {
      await Supabase.instance.client
          .from('user_events')
          .update({'status': 'award_pending'})
          .eq('event_id', widget.eventId)
          .eq('user_id', _currentUser!.id);
      
      setState(() {
        _isAwardPending = true;
        _isActionLoading = false;
      });
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
    final title = _event!['title'] ?? l10n.untitled;
    final description = _event!['description'] ?? '';
    final location = _event!['location'] ?? l10n.location;
    final points = _event!['points'] ?? 0;
    final category = _event!['category'] ?? 'General';
    final dateStrVal = _event!['date'];
    final dateObj = dateStrVal != null ? DateTime.parse(dateStrVal) : null;
    final dateStr = dateObj != null ? DateFormat('EEEE, MMM d, yyyy • hh:mm a').format(dateObj) : l10n.no_date;
    final creator = _event!['profiles'];
    final creatorName = creator?['full_name'] ?? 'Organizer';
    
    final isOwner = creator?['id'] == _currentUser?.id;
    final isJoined = eventProvider.isUserJoined(widget.eventId);
    final isOver = dateObj != null && dateObj.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_autoTranslate ? Icons.translate : Icons.g_translate_outlined, 
              color: const Color(0xFF6366F1),
            ),
            tooltip: 'Toggle Translation',
            onPressed: () => setState(() => _autoTranslate = !_autoTranslate),
          ),
          if (isOwner || (isJoined && !_isAwardPending))
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'approvals') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EventAwardApprovalScreen(event: _event!)),
                  );
                } else if (val == 'edit') {
                  _showEditEventDialog(context);
                } else if (val == 'delete') {
                  _onDeleteEvent();
                } else if (val == 'leave') {
                  _onLeaveEvent();
                }
              },
              itemBuilder: (context) => [
                if (isOwner) ...[
                  const PopupMenuItem(value: 'approvals', child: Text('Approvals')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
                if (isJoined && !_isAwardPending)
                  const PopupMenuItem(value: 'leave', child: Text('Withdraw from Event', style: TextStyle(color: Colors.red))),
              ],
              icon: const Icon(Icons.more_vert),
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_event?['image_url'] != null)
              CachedNetworkImage(
                imageUrl: _event!['image_url'],
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(height: 250, color: Colors.grey[100]),
              )
            else
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
                  FutureBuilder<String>(
                    future: _autoTranslate ? TranslationService.translate(title, 'hi') : Future.value(title),
                    builder: (context, snapshot) => Text(snapshot.data ?? title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(context, Icons.calendar_month_outlined, l10n.when, dateStr),
                  const SizedBox(height: 16),
                  _buildInfoRow(context, Icons.location_on_outlined, l10n.location, location),
                  const SizedBox(height: 16),
                  _buildInfoRow(context, Icons.stars_outlined, l10n.reward, '+$points ${l10n.points_unit}'),
                  Divider(height: 48, color: Theme.of(context).dividerColor.withOpacity(0.5), thickness: 1.5),
                  Text(l10n.about_event, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  FutureBuilder<String>(
                    future: _autoTranslate ? TranslationService.translate(description, 'hi') : Future.value(description),
                    builder: (context, snapshot) => Text(snapshot.data ?? description, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.6, fontSize: 15)),
                  ),
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
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: _isActionLoading 
            ? const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))))
            : (isJoined && !_isAwardPending && !isOwner && !isOver)
                ? Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: _onLeaveEvent,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            minimumSize: const Size.fromHeight(56),
                          ),
                          child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _onFinishEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            minimumSize: const Size.fromHeight(56),
                            elevation: 0,
                          ),
                          child: const Text('Mark as Done', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (isOwner || _isAwardPending || (isOver && !isJoined)) ? null : (isJoined ? _onFinishEvent : () => _onJoinEvent(l10n)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isOwner || _isAwardPending || (isOver && !isJoined)) ? Theme.of(context).dividerColor : const Color(0xFF6366F1),
                        foregroundColor: (isOwner || _isAwardPending || (isOver && !isJoined)) ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        isOwner ? l10n.your_event : (_isAwardPending ? 'Award Pending' : (isJoined ? 'Mark as Done' : (isOver ? 'Event Over' : l10n.join_event))),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  void _onDeleteEvent() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              final success = await SupabaseService.deleteEvent(widget.eventId);
              if (success && mounted) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _onLeaveEvent() async {
    if (_event == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw from Event'),
        content: const Text('Are you sure you want to withdraw? You will not earn points for this event.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isActionLoading = true);
              final int points = _event!['points'] ?? 0;
              
              final success = await context.read<EventProvider>().leaveEvent(widget.eventId, points);
              
              if (mounted) {
                setState(() => _isActionLoading = false);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Successfully withdrawn from the event.'), backgroundColor: Colors.orange),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to withdraw. Please try again.'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(event: _event),
      ),
    );
    
    if (result == true && mounted) {
      _loadData();
    }
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

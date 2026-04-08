import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/event_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../l10n/app_localizations.dart';
import 'event_award_approval_screen.dart';
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
    await context.read<EventProvider>().joinEvent(widget.eventId, points);
    
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
          if (isOwner)
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
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'approvals', child: Text('Approvals')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
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

  void _onDeleteEvent() async {
    final success = await SupabaseService.deleteEvent(widget.eventId);
    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showEditEventDialog(BuildContext context) {
    // Similarly to Edit Post, implement Edit Event.
    // For now, let's just make it simple.
    final titleController = TextEditingController(text: _event!['title']);
    final descController = TextEditingController(text: _event!['description']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Event'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await SupabaseService.updateEvent(
                eventId: widget.eventId,
                data: {
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                }
              );
              if (success && mounted) {
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('Save'),
          ),
        ],
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

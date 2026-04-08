import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/supabase_service.dart';
import '../../l10n/app_localizations.dart';
import '../profile/profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final results = await SupabaseService.fetchNotifications();
    if (mounted) {
      setState(() {
        _notifications = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _respond(Map<String, dynamic> notification, bool accept) async {
    final success = await SupabaseService.respondToFriendRequest(notification['id'].toString(), accept);
    if (success && mounted) {
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _notifications.isEmpty
              ? Center(child: Text('No new notifications', style: TextStyle(color: Theme.of(context).hintColor)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final note = _notifications[index];
                    final senderProfile = note['profiles'];
                    final type = note['type'];
                    final status = note['status'];
                    final message = note['message'] ?? 'New notification';
                    final String? profileUrl = senderProfile?['profile_picture'];

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profileUrl != null ? CachedNetworkImageProvider(profileUrl) : null,
                          child: profileUrl == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(message, style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                        subtitle: type == 'friend_request' && status == 'pending'
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _respond(note, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), elevation: 0),
                                      child: const Text('Accept', style: TextStyle(color: Colors.white)),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => _respond(note, false),
                                      child: Text('Decline', style: TextStyle(color: Theme.of(context).hintColor)),
                                    ),
                                  ],
                                ),
                              )
                            : status != null ? Text(status.toString().toUpperCase(), style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))) : null,
                        onTap: () {
                          if (senderProfile != null) {
                             Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ProfileScreen(userId: senderProfile['id'].toString())),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}


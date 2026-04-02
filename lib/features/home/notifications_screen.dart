import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';
import '../../l10n/app_localizations.dart';
import '../profile/profile_screen.dart'; // Reuse logic if possible, or create UserProfileScreen

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<ParseObject> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final results = await ParseService.fetchNotifications();
    if (mounted) {
      setState(() {
        _notifications = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _respond(ParseObject notification, bool accept) async {
    final success = await ParseService.respondToFriendRequest(notification, accept);
    if (success && mounted) {
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
=======
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
>>>>>>> 8c21739 (updates : dark mode, fixing post cards, adding friends page, making notificational panel working)
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _notifications.isEmpty
<<<<<<< HEAD
              ? const Center(child: Text('No new notifications', style: TextStyle(color: Colors.grey)))
=======
              ? Center(child: Text('No new notifications', style: TextStyle(color: Theme.of(context).hintColor)))
>>>>>>> 8c21739 (updates : dark mode, fixing post cards, adding friends page, making notificational panel working)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final note = _notifications[index];
                    final sender = note.get<ParseUser>('sender');
                    final type = note.get<String>('type');
                    final status = note.get<String>('status');
                    final message = note.get<String>('message') ?? 'New notification';
                    final profilePic = sender?.get('profilePicture');
                    String? profileUrl;
                    if (profilePic is ParseFileBase) profileUrl = profilePic.url;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
<<<<<<< HEAD
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
=======
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
>>>>>>> 8c21739 (updates : dark mode, fixing post cards, adding friends page, making notificational panel working)
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profileUrl != null ? CachedNetworkImageProvider(profileUrl) : null,
                          child: profileUrl == null ? const Icon(Icons.person) : null,
                        ),
<<<<<<< HEAD
                        title: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
=======
                        title: Text(message, style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
>>>>>>> 8c21739 (updates : dark mode, fixing post cards, adding friends page, making notificational panel working)
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
<<<<<<< HEAD
                                      child: const Text('Decline', style: TextStyle(color: Colors.grey)),
=======
                                      child: Text('Decline', style: TextStyle(color: Theme.of(context).hintColor)),
>>>>>>> 8c21739 (updates : dark mode, fixing post cards, adding friends page, making notificational panel working)
                                    ),
                                  ],
                                ),
                              )
<<<<<<< HEAD
                            : status != null ? Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.blueGrey)) : null,
=======
                            : status != null ? Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))) : null,
>>>>>>> 8c21739 (updates : dark mode, fixing post cards, adding friends page, making notificational panel working)
                        onTap: () {
                          if (sender != null) {
                             Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ProfileScreen(userId: sender.objectId)),
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/supabase_service.dart';
import 'chat_screen.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  List<Map<String, dynamic>> _chatPartners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final friends = await SupabaseService.getFriends();
      final activePartners = await SupabaseService.fetchChatPartners();
      
      // Combine and remove duplicates
      final Map<String, Map<String, dynamic>> combined = {};
      
      for (var f in friends) {
        if (f['id'] != null) combined[f['id'].toString()] = f;
      }
      
      for (var p in activePartners) {
        if (p['id'] != null) combined[p['id'].toString()] = p;
      }

      if (mounted) {
        setState(() {
          _chatPartners = combined.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _chatPartners.isEmpty 
            ? Center(
                child: Text('No messages yet. Add some friends to chat!', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 16)),
              )
            : ListView.separated(
                itemCount: _chatPartners.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.5)),
                itemBuilder: (context, index) {
                  final user = _chatPartners[index];
                  final String fullName = user['full_name'] ?? user['username'] ?? 'User';
                  final String username = user['username'] ?? '';
                  final String? profileUrl = user['profile_picture'];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                      backgroundImage: profileUrl != null ? CachedNetworkImageProvider(profileUrl) : null,
                      child: profileUrl == null ? const Icon(Icons.person, color: Color(0xFF6366F1)) : null,
                    ),
                    title: Text(fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                    subtitle: Text('@$username', style: TextStyle(color: Theme.of(context).hintColor)),
                    trailing: Icon(Icons.chevron_right, color: Theme.of(context).hintColor),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)));
                    },
                  );
                },
              ),
    );
  }
}

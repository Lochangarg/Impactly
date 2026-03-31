import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';
import 'chat_screen.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  List<ParseUser> _chatPartners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final partners = await ParseService.fetchChatPartners();
    final friends = await ParseService.getFriends();
    
    // Merge partners and friends so users have someone to message easily
    final Set<String> partnerIds = partners.map((e) => e.objectId!).toSet();
    for (var friend in friends) {
      if (!partnerIds.contains(friend.objectId)) {
        partners.add(friend);
      }
    }

    if (mounted) {
      setState(() {
        _chatPartners = partners;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _chatPartners.isEmpty 
            ? const Center(
                child: Text('No messages yet. Add some friends to chat!', style: TextStyle(color: Colors.grey, fontSize: 16)),
              )
            : ListView.separated(
                itemCount: _chatPartners.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                itemBuilder: (context, index) {
                  final user = _chatPartners[index];
                  final String fullName = user.get<String>('fullName') ?? user.username ?? 'User';
                  final String username = user.username ?? '';
                  final dynamic profilePicRaw = user.get('profilePicture');
                  final String? profileUrl = profilePicRaw is ParseFileBase 
                      ? profilePicRaw.url 
                      : (profilePicRaw is String ? profilePicRaw : null);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                      backgroundImage: profileUrl != null ? CachedNetworkImageProvider(profileUrl) : null,
                      child: profileUrl == null ? const Icon(Icons.person, color: Color(0xFF6366F1)) : null,
                    ),
                    title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('@$username', style: const TextStyle(color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)));
                    },
                  );
                },
              ),
    );
  }
}

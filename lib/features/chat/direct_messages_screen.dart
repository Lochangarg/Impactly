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
                      backgroundImage: profileUrl != null ? CachedNetworkImageProvider(profileUrl!) : null,
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

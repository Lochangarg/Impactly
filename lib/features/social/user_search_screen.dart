import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';
import '../../l10n/app_localizations.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ParseUser> _searchResults = [];
  bool _isLoading = false;
  Set<String> _friendIds = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final friends = await ParseService.getFriends();
    if (mounted) {
      setState(() {
        _friendIds = friends.map((f) => f.objectId!).toSet();
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    final results = await ParseService.searchUsers(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFriend(ParseUser user) async {
    final success = await ParseService.toggleFriend(user);
    if (!mounted) return;
    
    if (success) {
      final isFriend = _friendIds.contains(user.objectId);
      if (!isFriend) {
          ParseService.sendFriendRequest(user);
      }
      setState(() {
        if (isFriend) {
          _friendIds.remove(user.objectId);
        } else {
          _friendIds.add(user.objectId!);
        }
      });
      
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFriend ? l10n.friend_removed : l10n.friend_added),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update friendship. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.search_users, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // It's now a tab
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.search_hint,
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _performSearch,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined, size: 80, color: Colors.grey[200]),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty ? 'Search for people' : l10n.no_users_found,
                              style: TextStyle(color: Colors.grey[500], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final fullName = user.get<String>('fullName') ?? user.username ?? 'User';
                          final username = user.username ?? '';
                          final isFriend = _friendIds.contains(user.objectId);
                          
                          final dynamic profilePicRaw = user.get('profilePicture');
                          final String? profileUrl = profilePicRaw is ParseFileBase 
                              ? profilePicRaw.url 
                              : (profilePicRaw is String ? profilePicRaw : null);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ProfileScreen(userId: user.objectId)),
                                    );
                                  },
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                    backgroundImage: profileUrl != null ? CachedNetworkImageProvider(profileUrl) : null,
                                    child: profileUrl == null ? const Icon(Icons.person, color: Color(0xFF6366F1)) : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => ProfileScreen(userId: user.objectId)),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('@$username', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.message_outlined, color: Color(0xFF6366F1)),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)));
                                  },
                                ),
                                ElevatedButton(
                                  onPressed: () => _toggleFriend(user),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFriend ? Colors.grey[200] : const Color(0xFF6366F1),
                                    foregroundColor: isFriend ? Colors.black87 : Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: Text(
                                    isFriend ? l10n.remove_friend : l10n.add_friend,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

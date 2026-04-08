import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/supabase_service.dart';
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
  List<Map<String, dynamic>> _userResults = [];
  List<Map<String, dynamic>> _postResults = [];
  bool _isLoading = false;
  Set<String> _friendIds = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final friends = await SupabaseService.getFriends();
    if (mounted) {
      setState(() {
        _friendIds = friends.map((f) => f['id'].toString()).toSet();
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _userResults = []; _postResults = []; });
      return;
    }

    setState(() => _isLoading = true);
    final users = await SupabaseService.searchUsers(query);
    final posts = await SupabaseService.searchPosts(query);
    
    if (mounted) {
      setState(() {
        _userResults = users;
        _postResults = posts;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFriend(Map<String, dynamic> user) async {
    final userId = user['id'].toString();
    final success = await SupabaseService.toggleFriend(userId);
    if (!mounted) return;
    
    if (success) {
      final isFriend = _friendIds.contains(userId);
      if (!isFriend) {
          SupabaseService.sendFriendRequest(userId);
      }
      setState(() {
        if (isFriend) {
          _friendIds.remove(userId);
        } else {
          _friendIds.add(userId);
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(l10n.search_users, style: const TextStyle(fontWeight: FontWeight.bold)),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'People'),
              Tab(text: 'Posts'),
            ],
            indicatorColor: Color(0xFF6366F1),
            labelColor: Color(0xFF6366F1),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search people or posts...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: _performSearch,
              ),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : TabBarView(
                    children: [
                      // People Tab
                      _userResults.isEmpty
                        ? _buildEmptySearch('people')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _userResults.length,
                            itemBuilder: (context, index) => _buildUserTile(_userResults[index]),
                          ),
                      // Posts Tab
                      _postResults.isEmpty
                        ? _buildEmptySearch('posts')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _postResults.length,
                            itemBuilder: (context, index) => _buildPostTile(_postResults[index]),
                          ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearch(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(type == 'people' ? Icons.person_search_outlined : Icons.post_add_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? 'Search for $type' : 'No $type found',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final l10n = AppLocalizations.of(context)!;
    final fullName = user['full_name'] ?? user['username'] ?? 'User';
    final username = user['username'] ?? '';
    final userId = user['id'].toString();
    final isFriend = _friendIds.contains(userId);
    final String? profileUrl = user['profile_picture'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: profileUrl != null ? CachedNetworkImageProvider(profileUrl) : null,
            child: profileUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('@$username', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _toggleFriend(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFriend ? Colors.grey[200] : const Color(0xFF6366F1),
              foregroundColor: isFriend ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isFriend ? 'Remove' : 'Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTile(Map<String, dynamic> post) {
    final user = post['profiles'];
    final content = post['content'] ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(child: Text((user?['full_name'] ?? 'U')[0])),
        title: Text(user?['full_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () {
           // Navigate to post detail
        },
      ),
    );
  }
}

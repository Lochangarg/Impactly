import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/supabase_service.dart';
import 'edit_profile_screen.dart';
import '../language/screens/language_selection_screen.dart';
import '../../l10n/app_localizations.dart';
import 'settings_screen.dart';
import '../chat/chat_screen.dart';


class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _userFriends = [];
  List<Map<String, dynamic>> _userEvents = [];
  late TabController _tabController;
  bool _isMe = true;
  String _friendshipStatus = 'None'; // None, Friends, PendingSent, PendingReceived

  @override
  void initState() {
    super.initState();
    final me = Supabase.instance.client.auth.currentUser;
    _isMe = widget.userId == null || widget.userId == me?.id;
    _tabController = TabController(length: _isMe ? 3 : 2, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final me = Supabase.instance.client.auth.currentUser;
      Map<String, dynamic>? user;
      
      if (_isMe) {
        if (me != null) {
          user = await SupabaseService.fetchUserDetails(me.id);
        }
      } else {
        user = await SupabaseService.fetchUserDetails(widget.userId!);
        // Check friendship status
        _friendshipStatus = await SupabaseService.checkFriendshipStatus(widget.userId!);
      }

      if (user != null) {
        final posts = await SupabaseService.fetchUserPosts(user['id']);
        final friends = await SupabaseService.getFriends(userId: user['id']);
        
        List<Map<String, dynamic>> displayedFriends = friends;
        List<Map<String, dynamic>> joinedEvents = [];
        
        if (_isMe) {
          joinedEvents = await SupabaseService.fetchJoinedEvents();
        } else if (me != null) {
          // Calculate Mutual Friends
          final myFriends = await SupabaseService.getFriends(userId: me.id);
          final myFriendIds = myFriends.map((f) => f['id']).toSet();
          displayedFriends = friends.where((f) => myFriendIds.contains(f['id'])).toList();
        }

        if (mounted) {
          setState(() {
            _currentUser = user;
            _userPosts = posts;
            _userFriends = displayedFriends;
            _userEvents = joinedEvents;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String username = _currentUser?['username'] ?? l10n.profile;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              if (_isMe) {
                 showModalBottomSheet(
                   context: context,
                   builder: (context) => Container(
                     padding: const EdgeInsets.symmetric(vertical: 20),
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         ListTile(
                           leading: const Icon(Icons.edit_outlined),
                           title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                           onTap: () {
                             Navigator.pop(context);
                             _navigateToEdit();
                           },
                         ),
                         ListTile(
                           leading: const Icon(Icons.settings_outlined),
                           title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                           onTap: () {
                             Navigator.pop(context);
                             Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => const SettingsScreen()),
                             );
                           },
                         ),
                         const Divider(),
                         SwitchListTile(
                           title: const Text('Private Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                           subtitle: const Text('Hide your posts from non-members'),
                           value: _currentUser?['is_private'] ?? false,
                           activeColor: const Color(0xFF6366F1),
                           onChanged: (val) async {
                             Navigator.pop(context);
                             await SupabaseService.updateProfile(userId: _currentUser!['id'], data: {'is_private': val});
                             _loadAllData();
                           },
                         ),
                         ListTile(
                           leading: const Icon(Icons.logout, color: Colors.red),
                           title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                           onTap: () async {
                             await SupabaseService.signOut();
                             if (mounted) {
                               Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                             }
                           },
                         ),
                       ],
                     ),
                   ),
                 );
              } else {
                // Show user actions for others
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _currentUser == null
              ? Center(child: Text(l10n.user_not_found))
              : RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: const Color(0xFF6366F1),
                  child: NestedScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: _buildProfileHeader(_currentUser!),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            controller: _tabController,
                            indicatorColor: const Color(0xFF6366F1),
                            indicatorWeight: 3,
                            labelColor: Theme.of(context).colorScheme.onSurface,
                            unselectedLabelColor: Colors.grey,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            tabs: [
                              const Tab(text: 'Posts'),
                              const Tab(text: 'Friends'),
                              if (_isMe) const Tab(text: 'Events'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPostGrid(l10n),
                        _buildFriendsTab(l10n),
                        if (_isMe) _buildEventsTab(l10n),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> user) {
    final String fullName = user['full_name'] ?? 'User';
    final String? imageUrl = user['profile_picture'];
    final int points = user['points'] ?? 0;
    final int level = user['level'] ?? 1;
    final List<dynamic> interests = user['interests'] ?? [];
    final String bio = user['bio'] ?? 'Dedicated to making a positive impact in the community.';
    final String pronouns = user['pronouns'] ?? 'he/him';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            CircleAvatar(
              radius: 46,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImageProvider(imageUrl)
                  : null,
              child: imageUrl == null || imageUrl.isEmpty
                  ? Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
            const SizedBox(width: 20),
            // Impact Points Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Impact Points', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$points', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                          child: Text('Level $level', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        const Text('• View Ranking >', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Name and Bio
        Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(pronouns, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(bio, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
        const SizedBox(height: 16),
        // Social Interaction Buttons (if not me)
        if (!_isMe)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_friendshipStatus == 'PendingSent') 
                      ? null 
                      : () => _handleFollowToggle(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _friendshipStatus == 'Friends' ? Colors.grey[200] : const Color(0xFF6366F1),
                      foregroundColor: _friendshipStatus == 'Friends' ? Colors.black87 : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      _friendshipStatus == 'Friends' 
                        ? 'Unfriend' 
                        : (_friendshipStatus == 'PendingSent' ? 'Requested' : (_friendshipStatus == 'PendingReceived' ? 'Respond in Inbox' : 'Add Friend')), 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _friendshipStatus == 'Friends' ? () {
                      if (_currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(otherUser: _currentUser!),
                          ),
                        );
                      }
                    } : null,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: _friendshipStatus == 'Friends' ? const Color(0xFF6366F1) : Colors.grey[300]!),
                      foregroundColor: _friendshipStatus == 'Friends' ? const Color(0xFF6366F1) : Colors.grey,
                    ),
                    child: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        // Interests Tiles
        if (interests.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.take(6).map((interest) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(interest.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
            )).toList(),
          ),
      ],
    );
  }

  void _handleFollowToggle() async {
    if (_currentUser == null) return;
    
    if (_friendshipStatus == 'PendingReceived') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Friend Request'),
          content: const Text('Do you want to accept or decline this request?'),
          actions: [
            TextButton(
              onPressed: () async {
                 Navigator.pop(context);
                 final success = await SupabaseService.respondToFriendRequest(_currentUser!['id'], false);
                 if (success) _loadAllData();
              },
              child: const Text('Decline'),
            ),
            ElevatedButton(
              onPressed: () async {
                 Navigator.pop(context);
                 final success = await SupabaseService.respondToFriendRequest(_currentUser!['id'], true);
                 if (success) _loadAllData();
              },
              child: const Text('Accept'),
            ),
          ]
        )
      );
      return;
    }

    final success = await SupabaseService.toggleFriend(_currentUser!['id']);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend status updated!'), backgroundColor: Colors.green),
      );
      _loadAllData();
    }
  }

  Widget _buildStatItem(String count, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPostGrid(AppLocalizations l10n) {
    if (!_isMe && (_currentUser?['is_private'] ?? false)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              'This account is private',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Follow this user to see their posts and impact.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 80, color: Theme.of(context).hintColor.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(_isMe ? "No posts yet" : "No posts found", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(_isMe ? "Capture your impact and share it with the community." : "This user hasn't shared any updates yet.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1, mainAxisSpacing: 1),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        final String? imageUrl = post['image_url'];

        return Container(
          color: Theme.of(context).cardColor,
          child: imageUrl != null && imageUrl.isNotEmpty
              ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
              : Center(child: Icon(Icons.article_outlined, color: Theme.of(context).hintColor)),
        );
      },
    );
  }

  Widget _buildFriendsTab(AppLocalizations l10n) {
    if (_userFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Theme.of(context).hintColor.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text(_isMe ? "You haven't added any friends" : "No mutual friends found", 
              style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _userFriends.length,
      itemBuilder: (context, index) {
        final friend = _userFriends[index];
        final String name = friend['full_name'] ?? friend['username'] ?? 'User';
        final String? picUrl = friend['profile_picture'];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: picUrl != null ? CachedNetworkImageProvider(picUrl) : null,
              child: picUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('@${friend['username'] ?? ''}', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(userId: friend['id'].toString())),
              );
            },
          ),
        );
      },
    );
  }
  Widget _buildEventsTab(AppLocalizations l10n) {
    if (_userEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_outlined, size: 64, color: Theme.of(context).hintColor.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text("You haven't joined any events yet", 
              style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _userEvents.length,
      itemBuilder: (context, index) {
        final event = _userEvents[index];
        final String title = event['title'] ?? 'Event';
        final String category = event['category'] ?? 'General';
        
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_month_outlined, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(category, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () {},
          ),
        );
      },
    );
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(initialData: {
        'fullName': _currentUser!['full_name'],
        'username': _currentUser!['username'],
        'phone': _currentUser!['phone'],
        'location': _currentUser!['city'],
        'interests': _currentUser!['interests'],
        'profilePicUrl': _currentUser!['profile_picture'],
      })),
    );
    if (result == true) _loadAllData();
  }
}

  class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).cardColor, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

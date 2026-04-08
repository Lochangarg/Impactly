import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/supabase_service.dart';
import 'edit_profile_screen.dart';
import '../language/screens/language_selection_screen.dart';
import '../../l10n/app_localizations.dart';
import 'settings_screen.dart';

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
  late TabController _tabController;
  bool _isMe = true;

  @override
  void initState() {
    super.initState();
    _isMe = widget.userId == null;
    _tabController = TabController(length: _isMe ? 2 : 1, vsync: this);
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
        if (user?['id'] == me?.id) {
          _isMe = true;
        }
      }

      if (user != null) {
        final posts = await SupabaseService.fetchUserPosts(user['id']);
        final friends = await SupabaseService.getFriends(userId: user['id']);
        if (mounted) {
          setState(() {
            _currentUser = user;
            _userPosts = posts;
            _userFriends = friends;
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.profile, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          if (_isMe)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.settings,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
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
                          padding: const EdgeInsets.all(24.0),
                          child: _buildProfileHeader(_currentUser!),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            controller: _tabController,
                            indicatorColor: const Color(0xFF6366F1),
                            labelColor: const Color(0xFF6366F1),
                            unselectedLabelColor: Colors.grey,
                            tabs: [
                              Tab(icon: const Icon(Icons.grid_on), text: l10n.posts),
                              if (_isMe) Tab(icon: const Icon(Icons.people_outline), text: l10n.friends),
                            ],
                          ),
                        ),
                      ),
                    ],
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPostGrid(l10n),
                        if (_isMe) _buildFriendsTab(l10n),
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
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFF6366F1),
          backgroundImage: imageUrl != null && imageUrl.isNotEmpty
              ? CachedNetworkImageProvider(imageUrl)
              : null,
          child: imageUrl == null || imageUrl.isEmpty
              ? const Icon(Icons.person, size: 50, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 16),
        Text(fullName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 4),
        Text(l10n.points_and_level(points, level), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatItem(_userPosts.length.toString(), l10n.posts, () {
              _tabController.animateTo(0);
            }),
            Container(width: 1, height: 24, color: Theme.of(context).dividerColor, margin: const EdgeInsets.symmetric(horizontal: 24)),
            _buildStatItem(_userFriends.length.toString(), l10n.friends, _isMe ? () {
              _tabController.animateTo(1);
            } : null),
          ],
        ),
      ],
    );
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
    if (_userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.black54),
            const SizedBox(height: 12),
            Text(l10n.no_events_added, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(l10n.profile_caption, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
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
            Text(_isMe ? "You haven't added any friends" : "No friends to show", 
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

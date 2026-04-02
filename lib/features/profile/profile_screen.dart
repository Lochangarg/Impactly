import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';
import 'edit_profile_screen.dart';
import '../language/screens/language_selection_screen.dart';
import '../../l10n/app_localizations.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final String? _targetUserId;
  ParseUser? _currentUser;
  bool _isLoading = true;
  List<ParseObject> _userPosts = [];
  List<ParseUser> _userFriends = [];
  late TabController _tabController;
  bool _isMe = true;

  _ProfileScreenState(this._targetUserId);

  @override
  void initState() {
    super.initState();
    _isMe = _targetUserId == null;
    _tabController = TabController(length: _isMe ? 2 : 1, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      ParseUser? user;
      if (_isMe) {
        user = await ParseUser.currentUser() as ParseUser?;
        if (user != null) await user.fetch();
      } else {
        user = await ParseService.fetchUserDetails(_targetUserId!);
        final me = await ParseUser.currentUser() as ParseUser?;
        if (user?.objectId == me?.objectId) {
          _isMe = true;
        }
      }

      if (user != null) {
        final posts = await ParseService.fetchUserPosts(user);
        final friends = await ParseService.getFriends(user: user);
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

  Widget _buildProfileHeader(ParseUser user) {
    final String fullName = user.get<String>('fullName') ?? 'User';
    final dynamic file = user.get('profilePicture');
    String? imageUrl;
    if (file is ParseFileBase) {
      imageUrl = file.url;
    } else if (file is String) {
      imageUrl = file;
    }

    final int points = user.get<int>('totalXP') ?? 0;
    final int level = user.get<int>('level') ?? 1;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFF6366F1),
          backgroundImage: imageUrl != null && imageUrl.isNotEmpty
              ? NetworkImage("$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}")
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
        final dynamic file = post.get('image');
        String? imageUrl;
        if (file is ParseFileBase) imageUrl = file.url;

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
        final String name = friend.get<String>('fullName') ?? friend.username ?? 'User';
        final dynamic pic = friend.get('profilePicture');
        String? picUrl;
        if (pic is ParseFileBase) picUrl = pic.url;

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
            subtitle: Text('@${friend.username}', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(userId: friend.objectId)),
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
        'fullName': _currentUser!.get<String>('fullName'),
        'username': _currentUser!.username,
        'phone': _currentUser!.get<String>('phone'),
        'location': _currentUser!.get<String>('location'),
        'interests': _currentUser!.get<List<dynamic>>('interests'),
        'profilePicUrl': () {
          final dynamic f = _currentUser!.get('profilePicture');
          return f is ParseFileBase ? f.url : (f is String ? f : null);
        }(),
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

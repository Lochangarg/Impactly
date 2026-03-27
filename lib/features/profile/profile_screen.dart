import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  ParseUser? _currentUser;
  bool _isLoading = true;
  List<ParseObject> _userPosts = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      if (user != null) {
        await user.fetch();
        final posts = await ParseService.fetchUserPosts(user);
        if (mounted) {
          setState(() {
            _currentUser = user;
            _userPosts = posts;
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2))
          : _currentUser == null
              ? const Center(child: Text('User not found'))
              : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 20,
      title: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: Colors.black),
          const SizedBox(width: 8),
          Text(
            _currentUser?.username ?? 'profile',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(icon: const Icon(Icons.add_box_outlined, color: Colors.black), onPressed: () {}),
        IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: _showSettingsSheet),
      ],
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 5, width: 40, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
          ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Settings and privacy'), onTap: () => Navigator.pop(context)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _currentUser?.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderStats(),
                const SizedBox(height: 12),
                _buildProfileBio(),
                const SizedBox(height: 16),
                _buildActionButtons(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverAppBarDelegate(
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.black,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 1,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on_outlined)),
                Tab(icon: Icon(Icons.person_pin_outlined)),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostGrid(),
          const Center(child: Text('Mentions of you will appear here')),
        ],
      ),
    );
  }

  Widget _buildHeaderStats() {
    final dynamic file = _currentUser!.get('profilePicture');
    String? imageUrl;
    if (file is ParseFileBase) imageUrl = file.url;
    else if (file is String) imageUrl = file;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: Colors.grey[200],
          backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
          child: imageUrl == null || imageUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
        ),
        _buildStatItem(_userPosts.length.toString(), 'Posts'),
        _buildStatItem((_currentUser!.get<int>('points') ?? 0).toString(), 'Impact'),
        _buildStatItem((_currentUser!.get<int>('level') ?? 1).toString(), 'Level'),
      ],
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }

  Widget _buildProfileBio() {
    final String fullName = _currentUser!.get<String>('fullName') ?? 'User';
    final String location = _currentUser!.get<String>('location') ?? 'Earth';
    final List<dynamic> interests = _currentUser!.get<List<dynamic>>('interests') ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const Text('Community Leader', style: TextStyle(color: Colors.grey, fontSize: 13)), // Placeholder category
        Text('📍 Traveling from $location', style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: interests.map((i) => Text('#$i', style: const TextStyle(color: Color(0xFF00376B), fontSize: 13))).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _navigateToEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Text('Share Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.person_add_outlined, size: 18),
        ),
      ],
    );
  }

  Widget _buildPostGrid() {
    if (_userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.black54),
            const SizedBox(height: 12),
            const Text('No Posts Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            Text('Capture your impact and share it with the community.', style: TextStyle(color: Colors.grey[600], fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1, mainAxisSpacing: 1),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        final dynamic file = post.get('image');
        String? imageUrl;
        if (file is ParseFileBase) imageUrl = file.url;

        return Container(
          color: Colors.grey[100],
          child: imageUrl != null && imageUrl.isNotEmpty
              ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
              : const Center(child: Icon(Icons.article_outlined, color: Colors.grey)),
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
    return Container(color: Colors.white, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

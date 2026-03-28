import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';
import 'edit_profile_screen.dart';
import '../language/screens/language_selection_screen.dart';
import '../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () async {
              await _currentUser?.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _currentUser == null
              ? const Center(child: Text('User not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      _buildProfileHeader(_currentUser!),
                      const SizedBox(height: 32),
                      _buildProfileItem(Icons.email_outlined, 'Email', _currentUser!.emailAddress ?? 'No email'),
                      _buildProfileItem(Icons.phone_outlined, 'Phone', _currentUser!.get<String>('phone') ?? 'No phone'),
                      _buildProfileItem(Icons.location_on_outlined, 'Location', _currentUser!.get<String>('location') ?? 'No location'),
                      const SizedBox(height: 24),
                      const Align(alignment: Alignment.centerLeft, child: Text('Interests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 12),
                      _buildInterests(_currentUser!),
                      const SizedBox(height: 32),
                      _buildEditButton(context, _currentUser!),
                    ],
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
        Text(fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text('${user.get<int>('points') ?? 0} Points • Level ${user.get<int>('level') ?? 1}', style: const TextStyle(color: Color(0xFF6366F1))),
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

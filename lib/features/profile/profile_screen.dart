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
      appBar: _buildAppBar(l10n),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2))
          : _currentUser == null
              ? Center(child: Text(l10n.user_not_found))
              : _buildBody(l10n),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
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
        IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () => _showSettingsSheet(l10n)),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.black),
          tooltip: l10n.settings,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        )
      ],
    );
  }

  void _showSettingsSheet(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 5, width: 40, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
          ListTile(leading: const Icon(Icons.settings_outlined), title: Text(l10n.settings), onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
          }),
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

  Widget _buildBody(AppLocalizations l10n) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderStats(l10n),
                const SizedBox(height: 12),
                _buildProfileBio(),
                const SizedBox(height: 16),
                _buildActionButtons(l10n),
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
              tabs: [
                Tab(icon: const Icon(Icons.grid_on_outlined), text: l10n.posts),
                Tab(icon: const Icon(Icons.info_outline), text: l10n.info),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostGrid(l10n),
          _buildInfoTab(l10n),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(AppLocalizations l10n) {
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
        _buildStatItem(_userPosts.length.toString(), l10n.posts),
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

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _navigateToEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text(l10n.edit_profile, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget _buildInfoTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileItem(Icons.email_outlined, l10n.email, _currentUser!.emailAddress ?? 'No email'),
          _buildProfileItem(Icons.phone_outlined, l10n.phone, _currentUser!.get<String>('phone') ?? 'No phone'),
          _buildProfileItem(Icons.location_on_outlined, l10n.location, _currentUser!.get<String>('location') ?? 'No location'),
          const SizedBox(height: 24),
          Text(l10n.interests, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInterests(_currentUser!, l10n),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterests(ParseUser user, AppLocalizations l10n) {
    final List<dynamic> interests = user.get<List<dynamic>>('interests') ?? [];
    if (interests.isEmpty) return Text(l10n.no_interests_specified, style: const TextStyle(color: Colors.grey));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.map((interest) {
        final String interestStr = interest.toString();
        final String label = () {
          switch (interestStr) {
            case 'Music': return l10n.music;
            case 'Environment': return l10n.environment;
            case 'Art': return l10n.art;
            case 'Education': return l10n.education;
            case 'Community': return l10n.community;
            case 'Volunteering': return l10n.volunteering;
            case 'Animal Care': return l10n.animal_care;
            default: return interestStr;
          }
        }();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
        );
      }).toList(),
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
            Text(l10n.no_events_added, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
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

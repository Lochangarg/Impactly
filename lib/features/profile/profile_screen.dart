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
        title: Text(l10n.profile, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: l10n.logout_tooltip,
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
                              Tab(icon: const Icon(Icons.info_outline), text: l10n.info),
                              Tab(icon: const Icon(Icons.grid_on), text: l10n.posts),
                            ],
                          ),
                        ),
                      ),
                    ],
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInfoTab(l10n),
                        _buildPostGrid(l10n),
                      ],
                    ),
                  ),
                ),
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
          _buildEditButton(context, _currentUser!, l10n),
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

  Widget _buildEditButton(BuildContext context, ParseUser user, AppLocalizations l10n) {
    return ElevatedButton(
      onPressed: _navigateToEdit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Text(l10n.edit_profile, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

    final int points = user.get<int>('points') ?? 0;
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
        Text(fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(l10n.points_and_level(points, level), style: const TextStyle(color: Color(0xFF6366F1))),
      ],
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

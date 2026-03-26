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
class _ProfileScreenState extends State<ProfileScreen> {
  ParseUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      if (user != null) {
        await user.fetch();
        if (mounted) {
          setState(() {
            _currentUser = user;
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
  Widget build(BuildContext context) {
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

  Widget _buildInterests(ParseUser user) {
    final List<dynamic> interests = user.get<List<dynamic>>('interests') ?? [];
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: interests.map((interest) => Chip(
          label: Text(interest.toString()),
          backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
        )).toList(),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context, ParseUser user) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditProfileScreen(initialData: {
              'fullName': user.get<String>('fullName'),
              'username': user.username,
              'phone': user.get<String>('phone'),
              'location': user.get<String>('location'),
              'interests': user.get<List<dynamic>>('interests'),
              'profilePicUrl': () {
                final dynamic f = user.get('profilePicture');
                return f is ParseFileBase ? f.url : (f is String ? f : null);
              }(),
            })),
          );
          if (result == true) _loadUserData();
        },
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: const Text('Edit Profile'),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }
}

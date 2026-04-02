import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../../l10n/app_localizations.dart';
import 'edit_profile_screen.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  ParseUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.info, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _currentUser == null
              ? const Center(child: Text("User not found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
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
                      const SizedBox(height: 48),
                      _buildEditButton(context, _currentUser!, l10n),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
        );
      }).toList(),
    );
  }

  Widget _buildEditButton(BuildContext context, ParseUser user, AppLocalizations l10n) {
    return ElevatedButton(
      onPressed: () async {
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
        if (result == true) _loadUser();
      },
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
}

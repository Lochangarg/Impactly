import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/supabase_service.dart';
import 'edit_profile_screen.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final details = await SupabaseService.fetchUserDetails(user.id);
      if (mounted) {
        setState(() {
          _currentUser = details;
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
                      _buildProfileItem(Icons.email_outlined, l10n.email, Supabase.instance.client.auth.currentUser?.email ?? 'No email'),
                      _buildProfileItem(Icons.phone_outlined, l10n.phone, _currentUser!['phone'] ?? 'No phone'),
                      _buildProfileItem(Icons.location_on_outlined, l10n.location, _currentUser!['city'] ?? 'No location'),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterests(Map<String, dynamic> user, AppLocalizations l10n) {
    final List<dynamic> interests = user['interests'] ?? [];
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

  Widget _buildEditButton(BuildContext context, Map<String, dynamic> user, AppLocalizations l10n) {
    return ElevatedButton(
      onPressed: () async {
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/navigation/main_screen.dart';
import '../../core/services/supabase_service.dart';

class InterestCategory {
  final String title;
  final IconData icon;
  final Color baseColor;

  InterestCategory({required this.title, required this.icon, required this.baseColor});
}

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final List<InterestCategory> _categories = [
    InterestCategory(title: 'Environment', icon: Icons.eco_outlined, baseColor: const Color(0xFF10B981)),
    InterestCategory(title: 'Art', icon: Icons.palette_outlined, baseColor: const Color(0xFFF59E0B)),
    InterestCategory(title: 'Music', icon: Icons.music_note_outlined, baseColor: const Color(0xFFEC4899)),
    InterestCategory(title: 'Volunteering', icon: Icons.volunteer_activism_outlined, baseColor: const Color(0xFF6366F1)),
    InterestCategory(title: 'Community', icon: Icons.groups_outlined, baseColor: const Color(0xFF3B82F6)),
    InterestCategory(title: 'Education', icon: Icons.school_outlined, baseColor: const Color(0xFF8B5CF6)),
    InterestCategory(title: 'Animal Care', icon: Icons.pets_outlined, baseColor: const Color(0xFFEF4444)),
  ];

  final Set<String> _selectedInterests = {};
  bool _isLoading = false;

  void _toggleInterest(String title) {
    setState(() {
      if (_selectedInterests.contains(title)) {
        _selectedInterests.remove(title);
      } else {
        _selectedInterests.add(title);
      }
    });
  }

  Future<void> _saveInterests() async {
    if (_selectedInterests.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final success = await SupabaseService.updateProfile(
          userId: user.id,
          data: {
            'interests': _selectedInterests.toList(),
          },
        );
        
        if (success && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile. Please try again.'), backgroundColor: Colors.red),
          );
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User session lost. Please log in again.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving interests: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose your interests',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select at least one cause you care about to personalize your experience.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedInterests.contains(category.title);
                  
                  return GestureDetector(
                    onTap: () => _toggleInterest(category.title),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? category.baseColor.withOpacity(0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? category.baseColor : const Color(0xFFF3F4F6),
                          width: 2,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: category.baseColor.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ] : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category.icon,
                            size: 32,
                            color: isSelected ? category.baseColor : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            category.title,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? category.baseColor : const Color(0xFF4B5563),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_selectedInterests.isEmpty || _isLoading) ? null : _saveInterests,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Continue${_selectedInterests.isNotEmpty ? ' (${_selectedInterests.length})' : ''}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

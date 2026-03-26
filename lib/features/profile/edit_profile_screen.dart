import 'dart:io';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';
import '../auth/widgets/auth_field.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EditProfileScreen({super.key, required this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  
  File? _imageFile;
  final _picker = ImagePicker();
  
  final List<String> _interestOptions = [
    'Environment', 'Art', 'Music', 'Volunteering', 'Community', 'Education', 'Animal Care'
  ];
  late List<String> _selectedInterests;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['fullName']);
    _usernameController = TextEditingController(text: widget.initialData['username']);
    _phoneController = TextEditingController(text: widget.initialData['phone']?.replaceAll('+91', ''));
    _locationController = TextEditingController(text: widget.initialData['location']);
    _selectedInterests = List<String>.from(widget.initialData['interests'] ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final Map<String, dynamic> updateData = {
          'fullName': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'phone': '+91${_phoneController.text.trim()}',
          'location': _locationController.text.trim(),
          'interests': _selectedInterests,
        };

        if (_imageFile != null) {
          updateData['profilePicture'] = _imageFile;
        }

        final success = await ParseService.updateProfile(updateData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully! ✨'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilePicUrl = widget.initialData['profilePicUrl'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFF3F4F6),
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : (profilePicUrl != null && profilePicUrl.isNotEmpty
                              ? NetworkImage("$profilePicUrl?t=${DateTime.now().millisecondsSinceEpoch}")
                              : null),
                      child: (_imageFile == null && (profilePicUrl == null || profilePicUrl.isEmpty))
                          ? const Icon(Icons.person, size: 60, color: Color(0xFF9CA3AF))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              _buildLabel('Full Name'),
              AuthField(controller: _nameController, hintText: 'Full Name', prefixIcon: Icons.person_outline),
              const SizedBox(height: 16),

              _buildLabel('Username'),
              AuthField(controller: _usernameController, hintText: 'Username', prefixIcon: Icons.alternate_email),
              const SizedBox(height: 16),
              
              _buildLabel('Phone Number'),
              AuthField(
                controller: _phoneController, 
                hintText: '9876543210', 
                prefixIcon: Icons.phone_outlined,
                prefixText: '+91 ',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              _buildLabel('Location'),
              AuthField(controller: _locationController, hintText: 'City, Country', prefixIcon: Icons.location_on_outlined),
              
              const SizedBox(height: 24),
              _buildLabel('My Interests'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _interestOptions.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.add(interest);
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                    selectedColor: const Color(0xFF6366F1).withOpacity(0.1),
                    checkmarkColor: const Color(0xFF6366F1),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8), 
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151), fontSize: 13))
    );
  }
}

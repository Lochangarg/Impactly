import 'dart:io';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';
<<<<<<< HEAD
=======
import '../auth/widgets/auth_field.dart';
>>>>>>> 3cbf446 (initial impactly project)

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
<<<<<<< HEAD
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _pronounsController;
  
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isLoading = false;

=======
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  
  File? _imageFile;
  final _picker = ImagePicker();
  
>>>>>>> 3cbf446 (initial impactly project)
  final List<String> _interestOptions = [
    'Environment', 'Art', 'Music', 'Volunteering', 'Community', 'Education', 'Animal Care'
  ];
  late List<String> _selectedInterests;
<<<<<<< HEAD
=======
  
  bool _isLoading = false;
>>>>>>> 3cbf446 (initial impactly project)

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['fullName']);
    _usernameController = TextEditingController(text: widget.initialData['username']);
<<<<<<< HEAD
    _bioController = TextEditingController(text: widget.initialData['bio'] ?? '');
    _phoneController = TextEditingController(text: widget.initialData['phone']?.replaceAll('+91', ''));
    _locationController = TextEditingController(text: widget.initialData['location']);
    _pronounsController = TextEditingController(text: widget.initialData['pronouns'] ?? '');
=======
    _phoneController = TextEditingController(text: widget.initialData['phone']?.replaceAll('+91', ''));
    _locationController = TextEditingController(text: widget.initialData['location']);
>>>>>>> 3cbf446 (initial impactly project)
    _selectedInterests = List<String>.from(widget.initialData['interests'] ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
<<<<<<< HEAD
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _pronounsController.dispose();
=======
    _phoneController.dispose();
    _locationController.dispose();
>>>>>>> 3cbf446 (initial impactly project)
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
<<<<<<< HEAD
=======

>>>>>>> 3cbf446 (initial impactly project)
      try {
        final Map<String, dynamic> updateData = {
          'fullName': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
<<<<<<< HEAD
          'bio': _bioController.text.trim(),
          'phone': '+91${_phoneController.text.trim()}',
          'location': _locationController.text.trim(),
          'pronouns': _pronounsController.text.trim(),
=======
          'phone': '+91${_phoneController.text.trim()}',
          'location': _locationController.text.trim(),
>>>>>>> 3cbf446 (initial impactly project)
          'interests': _selectedInterests,
        };

        if (_imageFile != null) {
          updateData['profilePicture'] = _imageFile;
        }

        final success = await ParseService.updateProfile(updateData);

        if (success && mounted) {
<<<<<<< HEAD
=======
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully! ✨'), backgroundColor: Colors.green),
          );
>>>>>>> 3cbf446 (initial impactly project)
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
<<<<<<< HEAD
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
=======
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
>>>>>>> 3cbf446 (initial impactly project)
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
<<<<<<< HEAD
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.black, fontSize: 16)),
        ),
        leadingWidth: 80,
        title: const Text('Edit profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Done', style: TextStyle(color: Color(0xFF0095f6), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
=======
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
>>>>>>> 3cbf446 (initial impactly project)
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
<<<<<<< HEAD
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : (profilePicUrl != null && profilePicUrl.isNotEmpty
                              ? CachedNetworkImageProvider(profilePicUrl)
                              : null),
                      child: (_imageFile == null && (profilePicUrl == null || profilePicUrl.isEmpty))
                          ? const Icon(Icons.person, size: 44, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: const Text(
                        'Edit picture or avatar',
                        style: TextStyle(color: Color(0xFF0095f6), fontWeight: FontWeight.w600, fontSize: 14),
=======
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
>>>>>>> 3cbf446 (initial impactly project)
                      ),
                    ),
                  ],
                ),
              ),
<<<<<<< HEAD
              const SizedBox(height: 24),
              _buildEditField('Name', _nameController, hint: 'Your full name'),
              _buildEditField('Username', _usernameController, hint: 'Unique username'),
              _buildEditField('Pronouns', _pronounsController, hint: 'Add pronouns'),
              _buildEditField('Bio', _bioController, hint: 'Share about your impact', maxLines: null),
              
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text('Interests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _interestOptions.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) _selectedInterests.add(interest);
                          else _selectedInterests.remove(interest);
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: const Color(0xFF6366F1),
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 32, thickness: 0.2),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Private Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              const SizedBox(height: 12),
              _buildEditField('Phone', _phoneController, hint: '9876543210'),
              _buildEditField('Location', _locationController, hint: 'City, Country'),
              
              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Switch to professional account', style: TextStyle(color: Color(0xFF0095f6), fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 48),
=======
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
>>>>>>> 3cbf446 (initial impactly project)
            ],
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildEditField(String label, TextEditingController controller, {String? hint, int? maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                isDense: true,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),
          ),
        ],
      ),
=======
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8), 
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151), fontSize: 13))
>>>>>>> 3cbf446 (initial impactly project)
    );
  }
}

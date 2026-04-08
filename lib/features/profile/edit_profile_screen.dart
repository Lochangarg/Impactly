import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../core/services/supabase_service.dart';

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
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _pronounsController;
  
  Uint8List? _imageBytes;
  String? _fileExt;
  bool _removeImage = false;
  final _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> _interestOptions = [
    'Environment', 'Art', 'Music', 'Volunteering', 'Community', 'Education', 'Animal Care'
  ];
  late List<String> _selectedInterests;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['fullName']);
    _usernameController = TextEditingController(text: widget.initialData['username']);
    _bioController = TextEditingController(text: widget.initialData['bio'] ?? '');
    _phoneController = TextEditingController(text: widget.initialData['phone']?.replaceAll('+91', ''));
    _locationController = TextEditingController(text: widget.initialData['location']);
    _pronounsController = TextEditingController(text: widget.initialData['pronouns'] ?? '');
    _selectedInterests = List<String>.from(widget.initialData['interests'] ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _pronounsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      _fileExt = pickedFile.path.split('.').last;
      _removeImage = false;
      await _cropImage(pickedFile.path);
    }
  }

  void _onRemoveImage() {
    setState(() {
      _imageBytes = null;
      _fileExt = null;
      _removeImage = true;
    });
  }

  Future<void> _cropImage(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: const Color(0xFF6366F1),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true),
        IOSUiSettings(
          title: 'Crop Profile Picture',
        ),
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
        ),
      ],
    );

    if (croppedFile != null) {
      final bytes = await croppedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final Map<String, dynamic> updateData = {
          'full_name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'phone': '+91${_phoneController.text.trim()}',
          'city': _locationController.text.trim(),
          'interests': _selectedInterests,
        };

        if (_removeImage && _imageBytes == null) {
          updateData['profile_picture'] = null;
        }

        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return;

        final success = await SupabaseService.updateProfile(
          userId: user.id,
          data: updateData,
          imageBytes: _imageBytes,
          fileExt: _fileExt,
        );

        if (success && mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0.5,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
        ),
        leadingWidth: 80,
        title: Text('Edit profile', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save', style: TextStyle(color: Color(0xFF0095f6), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          backgroundImage: _imageBytes != null
                              ? MemoryImage(_imageBytes!) as ImageProvider
                              : (!_removeImage && profilePicUrl != null && profilePicUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(profilePicUrl)
                                  : null),
                          child: (_imageBytes == null && (_removeImage || (profilePicUrl == null || profilePicUrl.isEmpty)))
                              ? Icon(Icons.person_outline, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1),
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _pickImage,
                          child: const Text(
                            'Change Photo',
                            style: TextStyle(
                              color: Color(0xFF0095f6),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (_imageBytes != null || (profilePicUrl != null && profilePicUrl.isNotEmpty && !_removeImage))
                          TextButton(
                            onPressed: _onRemoveImage,
                            child: const Text(
                              'Remove Photo',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildEditField('Name', _nameController, hint: 'Your full name'),
              _buildEditField('Username', _usernameController, hint: 'Unique username'),
              _buildEditField('Pronouns', _pronounsController, hint: 'Add pronouns'),
              _buildEditField('Bio', _bioController, hint: 'Share about your impact', maxLines: null),
              
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text('Interests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _interestOptions.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) _selectedInterests.add(interest);
                          else _selectedInterests.remove(interest);
                        });
                      },
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      selectedColor: const Color(0xFF6366F1),
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 32, thickness: 0.2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Private Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              ),
              const SizedBox(height: 12),
              _buildEditField('Phone', _phoneController, hint: '9876543210'),
              _buildEditField('Location', _locationController, hint: 'City, Country'),
              
              const SizedBox(height: 32),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {String? hint, int? maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
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
              style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

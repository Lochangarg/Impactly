import 'dart:io';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/parse_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/translation_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  ParseObject? _selectedEvent;
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _autoTranslate = true;
  Future<List<ParseObject>>? _joinedEvents;

  @override
  void initState() {
    super.initState();
    _joinedEvents = ParseService.fetchJoinedEvents();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _onCreatePost(AppLocalizations l10n) async {
    if (_contentController.text.trim().isEmpty || _selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.write_something_error)),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      String content = _contentController.text.trim();
      
      if (_autoTranslate) {
        content = await TranslationService.translate(content, 'hi');
      }

      final success = await ParseService.createPost(
        content: content,
        event: _selectedEvent!,
        image: _imageFile,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.post_published), backgroundColor: Colors.green));
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.new_post, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
        actions: [
          Row(
            children: [
              const Text('Auto-Translate', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Switch(
                value: _autoTranslate,
                onChanged: (val) => setState(() => _autoTranslate = val),
                activeColor: const Color(0xFF6366F1),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          TextButton(
            onPressed: _isLoading ? null : () => _onCreatePost(l10n),
            child: Text(
              l10n.post,
              style: TextStyle(
                color: _isLoading ? Colors.grey : const Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Picker
            Text(l10n.event_update, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 12),
            FutureBuilder<List<ParseObject>>(
              future: _joinedEvents,
              builder: (context, snapshot) {
                final events = snapshot.data ?? [];
                if (events.isEmpty && snapshot.connectionState == ConnectionState.done) {
                  return Text(l10n.join_event_to_post);
                }
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ParseObject>(
                      value: _selectedEvent,
                      hint: Text(l10n.select_joined_event),
                      isExpanded: true,
                      items: events.map((e) {
                        return DropdownMenuItem(value: e, child: Text(e.get<String>('title') ?? 'Untitled'));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedEvent = val),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Content input
            TextField(
              controller: _contentController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: l10n.whats_the_update,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 18, color: Color(0xFF111827), height: 1.5),
            ),
            
            const SizedBox(height: 32),

            // Image Preview
            if (_imageFile != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_imageFile!, width: double.infinity, height: 250, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _imageFile = null),
                      child: const CircleAvatar(backgroundColor: Colors.black54, radius: 14, child: Icon(Icons.close, color: Colors.white, size: 16)),
                    ),
                  )
                ],
              ),
            
            const SizedBox(height: 20),
            
            // Image Picker Button
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(l10n.add_photo),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: const Color(0xFF6366F1),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

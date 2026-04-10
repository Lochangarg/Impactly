import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/supabase_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/translation_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  Map<String, dynamic>? _selectedEvent;
  Uint8List? _imageBytes;
  String? _fileExt;
  final _picker = ImagePicker();
  bool _isLoading = false;
  Future<List<Map<String, dynamic>>>? _joinedEvents;

  @override
  void initState() {
    super.initState();
    _joinedEvents = SupabaseService.fetchJoinedEvents();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fileExt = pickedFile.path.split('.').last;
      });
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

      final success = await SupabaseService.createPost(
        content: content,
        eventId: _selectedEvent!['id'].toString(),
        imageBytes: _imageBytes,
        fileExt: _fileExt,
      );

      if (success && mounted) {
        // Send notifications to all participants
        SupabaseService.sendEventNotifications(
          eventId: _selectedEvent!['id'].toString(),
          message: 'shared an update in ${_selectedEvent!['title']}',
          type: 'event_update',
        ).ignore(); // Run in background

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.new_post, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
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
            Text(l10n.event_update, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _joinedEvents,
              builder: (context, snapshot) {
                final events = snapshot.data ?? [];
                if (events.isEmpty && snapshot.connectionState == ConnectionState.done) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.explore),
                      label: Text(l10n.join_event_to_post),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  );
                }
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      value: _selectedEvent,
                      hint: Text(l10n.select_joined_event),
                      isExpanded: true,
                      items: events.map((e) {
                        return DropdownMenuItem(value: e, child: Text(e['title'] ?? 'Untitled'));
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
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface, height: 1.5),
            ),
            
            const SizedBox(height: 32),

            // Image Preview
            if (_imageBytes != null)
              Stack(
                children: [
                   ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(_imageBytes!, width: double.infinity, height: 250, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _imageBytes = null),
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
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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

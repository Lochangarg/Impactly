import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/supabase_service.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class CreateEventScreen extends StatefulWidget {
  final Map<String, dynamic>? event;
  const CreateEventScreen({super.key, this.event});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _pointsController = TextEditingController();
  String _selectedCategory = 'Cleaning';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  Uint8List? _imageBytes;
  String? _fileExt;
  final _picker = ImagePicker();

  final List<String> _categories = ['Cleaning', 'Workshops', 'Volunteering', 'Music', 'Social'];

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!['title'] ?? '';
      _descriptionController.text = widget.event!['description'] ?? '';
      _locationController.text = widget.event!['location'] ?? '';
      _pointsController.text = (widget.event!['points'] ?? 0).toString();
      _selectedCategory = widget.event!['category'] ?? 'Cleaning';
      
      final dateVal = widget.event!['date'];
      if (dateVal != null) {
        final dt = DateTime.parse(dateVal);
        _selectedDate = dt;
        _selectedTime = TimeOfDay.fromDateTime(dt);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF6366F1),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
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

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both date and time')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      bool success = false;
      if (widget.event != null) {
        // Update
        success = await SupabaseService.updateEvent(
          eventId: widget.event!['id'],
          data: {
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'location': _locationController.text.trim(),
            'category': _selectedCategory,
            'points': int.parse(_pointsController.text.trim()),
            'date': finalDateTime.toIso8601String(),
          },
          imageBytes: _imageBytes,
          fileExt: _fileExt,
        );
      } else {
        // Create
        success = await SupabaseService.createEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          category: _selectedCategory,
          points: int.parse(_pointsController.text.trim()),
          date: finalDateTime,
          imageBytes: _imageBytes,
          fileExt: _fileExt,
        );

        if (success) {
          // Broadcast to all users
          SupabaseService.broadcastNotification(
            message: 'A new event "${_titleController.text.trim()}" has been created.',
            type: 'new_event',
          ).ignore();
        }
      }

      if (success && mounted) {
        if (widget.event != null) {
          // Notify participants about the edit
          SupabaseService.sendEventNotifications(
            eventId: widget.event!['id'],
            message: 'updated the details for ${widget.event!['title']}',
            type: 'event_modified',
          ).ignore();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event != null ? 'Event Updated' : 'Event Created 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.event != null ? 'Edit Event' : l10n.create_new_event, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(l10n.event_title),
                _buildTextField(_titleController, l10n.event_title_hint, Icons.title, l10n: l10n),
                
                const SizedBox(height: 20),
                _buildLabel(l10n.description_label),
                _buildTextField(_descriptionController, l10n.description_hint, Icons.description, maxLines: 3, l10n: l10n),
                
                const SizedBox(height: 20),
                _buildLabel('Event Image'),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      image: _imageBytes != null 
                        ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                        : (widget.event?['image_url'] != null ? DecorationImage(image: NetworkImage(widget.event!['image_url']), fit: BoxFit.cover) : null),
                    ),
                    child: (_imageBytes == null && widget.event?['image_url'] == null)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                            const SizedBox(height: 8),
                            Text('Add photo to attract more volunteers', 
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 13)),
                          ],
                        )
                      : const SizedBox.shrink(),
                  ),
                ),
                
                const SizedBox(height: 20),
                _buildLabel(l10n.location_label),
                _buildTextField(_locationController, l10n.location_hint, Icons.location_on, l10n: l10n),
                
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(l10n.category),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                items: _categories.map((String category) {
                                  final String categoryLabel = () {
                                    switch (category) {
                                      case 'Cleaning': return l10n.cleaning;
                                      case 'Workshops': return l10n.workshops;
                                      case 'Volunteering': return l10n.volunteering;
                                      case 'Music': return l10n.music;
                                      case 'Social': return l10n.social;
                                      default: return category;
                                    }
                                  }();
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(categoryLabel, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedCategory = value!);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(l10n.points_reward),
                          _buildTextField(_pointsController, l10n.points_hint, Icons.stars, isNumber: true, l10n: l10n),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(l10n.event_date),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDate == null 
                                      ? l10n.select_date 
                                      : DateFormat('MMM d, yyyy').format(_selectedDate!),
                                    style: TextStyle(
                                      color: _selectedDate == null ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4) : Theme.of(context).colorScheme.onSurface,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Event Time'),
                          InkWell(
                            onTap: () => _selectTime(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedTime == null 
                                      ? 'Select Time'
                                      : _selectedTime!.format(context),
                                    style: TextStyle(
                                      color: _selectedTime == null ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4) : Theme.of(context).colorScheme.onSurface,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.event != null ? 'Save Changes' : l10n.create_event, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1, bool isNumber = false, required AppLocalizations l10n}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return l10n.field_required;
        if (isNumber && int.tryParse(value) == null) return l10n.valid_number;
        return null;
      },
    );
  }
}

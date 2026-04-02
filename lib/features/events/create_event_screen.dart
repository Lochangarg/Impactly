import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/translation_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _pointsController = TextEditingController();
  bool _autoTranslate = true;
  
  String _selectedCategory = 'Cleaning';
  DateTime? _selectedDate;
  bool _isLoading = false;

  final List<String> _categories = ['Cleaning', 'Workshops', 'Volunteering', 'Music', 'Social'];

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
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      
      String title = _titleController.text.trim();
      String description = _descriptionController.text.trim();
      String location = _locationController.text.trim();

      if (_autoTranslate) {
        title = await TranslationService.translate(title, 'hi');
        description = await TranslationService.translate(description, 'hi');
        location = await TranslationService.translate(location, 'hi');
      }

      final event = ParseObject('Events')
        ..set('title', title)
        ..set('description', description)
        ..set('location', location)
        ..set('category', _selectedCategory)
        ..set('points', int.parse(_pointsController.text.trim()))
        ..set('date', _selectedDate)
        ..set('createdBy', user?.toPointer());

      final response = await event.save();

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event Created 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw response.error!.message;
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
        title: Text(l10n.create_new_event, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              const Text('Auto-Hindi', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Switch(
                value: _autoTranslate,
                onChanged: (val) => setState(() => _autoTranslate = val),
                activeColor: const Color(0xFF6366F1),
              ),
            ],
          ),
        ],
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
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(l10n.create_event, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

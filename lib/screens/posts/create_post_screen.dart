import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/post_provider.dart';
import 'package:myapp/widgets/custom_button.dart';
import 'package:myapp/widgets/custom_text_field.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedMedia;
  bool _isEvent = false;
  DateTime? _eventDateTime;

  Future<void> _pickMedia() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (await file.length() > 10 * 1024 * 1024) {
          // 10MB limit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size too large (max 10MB)')),
          );
          return;
        }
        setState(() {
          _selectedMedia = file;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick media: ${e.toString()}')),
      );
    }
  }

  Future<void> _selectEventDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _eventDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_eventDateTime ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _eventDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isEvent && _eventDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event date and time.')),
      );
      return;
    }

    final postProvider = Provider.of<PostProvider>(context, listen: false);

    try {
      await postProvider.createPost(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        mediaFile: _selectedMedia,
        isEvent: _isEvent,
        eventDateTime: _eventDateTime,
        location:
            _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
      return;
    }

    if (!mounted) return;

    if (postProvider.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${postProvider.error}')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Post created successfully!')));

    // ✅ Smart return: pop if this screen was pushed; otherwise hand off to parent.
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop(true); // optionally return success
    } else {
      // We're likely in a tab body — notify parent instead
      // You can use a callback or a global notifier.
      // For now, push home:
      nav.pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: _titleController,
                    labelText: 'Title',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Title cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  CustomTextField(
                    controller: _descriptionController,
                    labelText: 'Description',
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Description cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Checkbox(
                        value: _isEvent,
                        onChanged: (bool? value) {
                          setState(() {
                            _isEvent = value ?? false;
                            if (!_isEvent) {
                              _eventDateTime = null;
                              _locationController.clear();
                            }
                          });
                        },
                      ),
                      const Text('Is this an event?'),
                    ],
                  ),
                  if (_isEvent) ...[
                    const SizedBox(height: 16.0),
                    CustomTextField(
                      controller: _locationController,
                      labelText: 'Event Location',
                      validator: (value) {
                        if (_isEvent && (value == null || value.isEmpty)) {
                          return 'Event location cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    InkWell(
                      onTap: () => _selectEventDateTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Event Date & Time',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                          errorText:
                              _eventDateTime == null && _isEvent
                                  ? 'Please select a date and time'
                                  : null,
                        ),
                        child: Text(
                          _eventDateTime == null
                              ? 'Select Date and Time'
                              : DateFormat(
                                'yyyy-MM-dd HH:mm',
                              ).format(_eventDateTime!),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16.0),
                  _selectedMedia == null
                      ? TextButton.icon(
                        onPressed: _pickMedia,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Photo'),
                      )
                      : Column(
                        children: [
                          Image.file(
                            _selectedMedia!,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                          TextButton.icon(
                            onPressed: _pickMedia,
                            icon: const Icon(Icons.change_circle),
                            label: const Text('Change Media'),
                          ),
                        ],
                      ),
                  const SizedBox(height: 24.0),
                  postProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                        text: 'Create Post',
                        onPressed: _createPost,
                        color: const Color.fromARGB(255, 118, 111, 126)
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

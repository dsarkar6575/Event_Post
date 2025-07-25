// screens/edit_post_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/providers/post_provider.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late bool _isEvent;
  DateTime? _eventDateTime;
  File? _newMediaFile;
  bool _clearExistingMedia = false;
  List<String> _currentMediaUrls = []; // Keep track of original media for display
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _descriptionController = TextEditingController(text: widget.post.description);
    _locationController = TextEditingController(text: widget.post.location ?? '');
    _isEvent = widget.post.isEvent;
    _eventDateTime = widget.post.eventDateTime;
    _currentMediaUrls = List.from(widget.post.mediaUrls); // Initialize with existing media
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _newMediaFile = File(pickedFile.path);
          _clearExistingMedia = false; // If a new image is picked, we are not clearing
                                     // all media; we are replacing or adding.
                                     // The backend logic will handle replacement.
          _currentMediaUrls = []; // Clear current media display as a new one is selected
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _selectEventDateTime() async {
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

  void _handleRemoveMedia() {
    setState(() {
      _newMediaFile = null; // Clear the newly selected file
      _clearExistingMedia = true; // Set flag to clear existing media on submit
      _currentMediaUrls = []; // Clear the display of existing media
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final postProvider = Provider.of<PostProvider>(context, listen: false);

      try {
        await postProvider.updatePost(
          widget.post.id,
          title: _titleController.text,
          description: _descriptionController.text,
          isEvent: _isEvent,
          eventDateTime: _isEvent ? _eventDateTime : null,
          location: _isEvent ? _locationController.text : null,
          newMediaFile: _newMediaFile,
          clearExistingMedia: _clearExistingMedia, // Pass the flag
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post updated successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update post: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          if (postProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      if (value.length > 100) {
                        return 'Title must be less than 100 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true, // Align label to top for multiline
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      if (value.length > 1000) {
                        return 'Description must be less than 1000 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Is this an Event?'),
                    value: _isEvent,
                    onChanged: (bool value) {
                      setState(() {
                        _isEvent = value;
                        if (!value) {
                          _eventDateTime = null;
                          _locationController.clear();
                        }
                      });
                    },
                  ),
                  if (_isEvent) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        _eventDateTime == null
                            ? 'Select Event Date and Time'
                            : 'Event Date: ${_eventDateTime!.toLocal().toString().split(' ')[0]}\nTime: ${_eventDateTime!.toLocal().toString().split(' ')[1].substring(0, 5)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectEventDateTime,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Post Media',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_newMediaFile != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _newMediaFile!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: _handleRemoveMedia,
                        ),
                      ],
                    )
                  else if (_currentMediaUrls.isNotEmpty && !_clearExistingMedia)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _currentMediaUrls.first,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image_not_supported, size: 50),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: _handleRemoveMedia,
                        ),
                      ],
                    )
                  else
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Choose Image'),
                      ),
                      const SizedBox(width: 8),
                      if (_newMediaFile != null ||
                          (_currentMediaUrls.isNotEmpty && !_clearExistingMedia))
                        ElevatedButton.icon(
                          onPressed: _handleRemoveMedia,
                          icon: const Icon(Icons.delete),
                          label: const Text('Remove'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Update Post',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
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
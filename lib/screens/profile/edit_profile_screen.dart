import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/user_provider.dart';
import 'package:myapp/widgets/custom_button.dart';
import 'package:myapp/widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  final ImagePicker _picker = ImagePicker();

  File? _newProfileImage;
  String? _currentProfileImageUrl;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _usernameController = TextEditingController(text: authProvider.currentUser?.username ?? '');
    _bioController = TextEditingController(text: authProvider.currentUser?.bio ?? '');
    _currentProfileImageUrl = authProvider.currentUser?.profileImageUrl;
  }

  Future<void> _pickProfileImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      await userProvider.updateUserProfile(
        authProvider.currentUser!.id,
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        profileImage: _newProfileImage,
      );

      if (userProvider.error == null) {
        // Update the AuthProvider's current user with the new data
        authProvider.updateCurrentUser(userProvider.viewedUser!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context); // Go back to profile screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userProvider.error ?? 'Failed to update profile.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage: _newProfileImage != null
                            ? FileImage(_newProfileImage!)
                            : (_currentProfileImageUrl != null
                                ? NetworkImage(_currentProfileImageUrl!)
                                : null) as ImageProvider<Object>?,
                        child: _newProfileImage == null && _currentProfileImageUrl == null
                            ? const Icon(Icons.add_a_photo, size: 40)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  CustomTextField(
                    controller: _usernameController,
                    labelText: 'Username',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  CustomTextField(
                    controller: _bioController,
                    labelText: 'Bio',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24.0),
                  userProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                          text: 'Save Changes',
                          onPressed: _updateProfile,
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
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'farmer_dashboard.dart';
import 'buyer_dashboard.dart';

class CompleteProfileScreen extends StatefulWidget {
  final bool isGoogleSignIn;
  final String? googleName;
  final String? googleProfilePicture;

  const CompleteProfileScreen({
    Key? key,
    required this.isGoogleSignIn,
    this.googleName,
    this.googleProfilePicture,
  }) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _profileImage;
  String? _selectedGender;
  String? _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name if from Google sign-in
    if (widget.isGoogleSignIn && widget.googleName != null) {
      _nameController.text = widget.googleName!;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackbar('Error picking image: $e');
    }
  }

  Future<String?> _uploadProfilePicture() async {
    if (_profileImage == null) {
      // If no new image selected but Google provided one, use that
      if (widget.isGoogleSignIn && widget.googleProfilePicture != null) {
        return widget.googleProfilePicture;
      }
      return null;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final String fileName = 'profile_${user.uid}.jpg';
      final Reference storageRef = _storage.ref().child('profile_pictures/$fileName');

      final UploadTask uploadTask = storageRef.putFile(_profileImage!);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty) {
      _showErrorSnackbar('Please enter your name');
      return false;
    }

    if (_selectedGender == null) {
      _showErrorSnackbar('Please select your gender');
      return false;
    }

    if (_ageController.text.isEmpty) {
      _showErrorSnackbar('Please enter your age');
      return false;
    }

    if (_selectedRole == null) {
      _showErrorSnackbar('Please select your role');
      return false;
    }

    final age = int.tryParse(_ageController.text);
    if (age == null || age < 1 || age > 120) {
      _showErrorSnackbar('Please enter a valid age');
      return false;
    }

    return true;
  }

  Future<void> _saveProfileAndRole() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showErrorSnackbar('User not authenticated');
        return;
      }

      // Upload profile picture and get URL
      final String? profilePictureUrl = await _uploadProfilePicture();

      // Create complete user profile
      final userData = {
        'email': user.email,
        'name': _nameController.text.trim(),
        'phone': user.phoneNumber,
        'profilePicture': profilePictureUrl,
        'gender': _selectedGender,
        'age': int.tryParse(_ageController.text),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isProfileComplete': true,
      };

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      print('✅ Profile and role saved successfully');

      // Navigate to appropriate dashboard
      if (_selectedRole == 'farmer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FarmerDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BuyerDashboard()),
        );
      }

    } catch (e) {
      print('Error saving profile: $e');
      _showErrorSnackbar('Error saving profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              "Let's set up your profile",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Complete your profile to get started with KrashiAI",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // Profile Picture Section
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (widget.isGoogleSignIn && widget.googleProfilePicture != null)
                            ? NetworkImage(widget.googleProfilePicture!)
                            : null,
                        child: _profileImage == null &&
                            (widget.googleProfilePicture == null || !widget.isGoogleSignIn)
                            ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isGoogleSignIn ? 'Photo from Google' : 'Add Profile Photo',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Personal Information Section
            _buildSectionHeader('Personal Information'),
            const SizedBox(height: 16),

            // Name Field
            Text(
              'Full Name ${widget.isGoogleSignIn ? '(from Google)' : ''}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 16),

            // Gender Selection
            const Text(
              'Gender',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildGenderOption('Male', Icons.male),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGenderOption('Female', Icons.female),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGenderOption('Other', Icons.transgender),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Age Field
            const Text(
              'Age',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter your age',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.cake),
              ),
            ),

            const SizedBox(height: 32),

            // Role Selection Section
            _buildSectionHeader('Select Your Role'),
            const SizedBox(height: 8),
            const Text(
              "How will you use KrashiAI? This helps us personalize your experience.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // Farmer Role Card
            _buildRoleCard(
              role: 'farmer',
              title: "I'm a Farmer",
              description: "Sell crops, get AI pricing, manage listings",
              icon: Icons.agriculture,
              color: Colors.green,
            ),

            const SizedBox(height: 16),

            // Buyer Role Card
            _buildRoleCard(
              role: 'buyer',
              title: "I'm a Buyer",
              description: "Browse listings, send offers, buy produce",
              icon: Icons.shopping_cart,
              color: Colors.orange,
            ),

            const SizedBox(height: 40),

            // Complete Profile Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfileAndRole,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Complete Profile & Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              "You can change your role later in settings",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              gender,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return Card(
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: color,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import '../services/ai_services.dart';

class SmartListingScreen extends StatefulWidget {
  const SmartListingScreen({Key? key}) : super(key: key);

  @override
  _SmartListingScreenState createState() => _SmartListingScreenState();
}

class _SmartListingScreenState extends State<SmartListingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _identifiedCrop;
  double? _suggestedPrice;
  bool _isAnalyzing = false;
  bool _isGettingPrice = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isAnalyzing = true;
          _identifiedCrop = null;
          _suggestedPrice = null;
        });

        await _analyzeImage();
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    try {
      final result = await AIServices.analyzeCropImage(_selectedImage!);

      setState(() {
        _isAnalyzing = false;
      });

      if (result['isCropDetected'] == true && result['identifiedCrop'] != null) {
        setState(() {
          _identifiedCrop = result['identifiedCrop'];
          _nameController.text = result['identifiedCrop']!;
        });

        await _getPriceSuggestion(result['identifiedCrop']!);

        _descriptionController.text =
        "Fresh ${result['identifiedCrop']!.toLowerCase()} "
            "harvested recently. Quality: ${result['quality']}.";

        _showAnalysisResult(result);
      } else {
        _showError('Could not identify crop. Please enter manually.');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showError('Analysis failed: $e');
    }
  }

  Future<void> _getPriceSuggestion(String crop) async {
    setState(() {
      _isGettingPrice = true;
    });

    try {
      final priceData = await AIServices.getPriceSuggestion(
        crop: crop,
        location: 'Punjab', // You can get this from user profile
      );

      setState(() {
        _suggestedPrice = priceData['suggested_price']?.toDouble();
        _priceController.text = _suggestedPrice?.toStringAsFixed(2) ?? '';
        _isGettingPrice = false;
      });
    } catch (e) {
      setState(() {
        _isGettingPrice = false;
      });
      _showError('Price suggestion failed: $e');
    }
  }

  void _showAnalysisResult(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crop Identified!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crop: ${result['identifiedCrop']}'),
            Text('Confidence: ${(result['confidence'] * 100).toStringAsFixed(1)}%'),
            Text('Quality: ${result['quality']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submitProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }

    try {
      await _firestore.collection('products').add({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text.isEmpty ? '1' : _quantityController.text),
        'description': _descriptionController.text,
        'farmerId': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'category': 'General',
        'quality': 'Medium',
        'ai_identified': _identifiedCrop != null,
        'ai_suggested_price': _suggestedPrice,
      });

      Navigator.pop(context);
      _showSuccess('Product listed successfully!');
    } catch (e) {
      _showError('Failed to list product: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Product Listing'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_camera),
            onPressed: _pickImage,
            tooltip: 'Take Photo for AI Analysis',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Image Preview
              if (_selectedImage != null) ...[
                Card(
                  child: Stack(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (_isAnalyzing)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black54,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                  SizedBox(height: 16),
                                  Text(
                                    'AI is analyzing your crop...',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Product Name with AI detection
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: const OutlineInputBorder(),
                  suffixIcon: _identifiedCrop != null
                      ? const Icon(Icons.auto_awesome, color: Colors.green)
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Price with AI suggestion
              Stack(
                children: [
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price per kg (₹)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (_isGettingPrice)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
              if (_suggestedPrice != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'AI Suggested: ₹${_suggestedPrice!.toStringAsFixed(2)}/kg',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Quantity
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'List Product with AI',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              // Camera Button if no image
              if (_selectedImage == null) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Use Camera for AI Analysis'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}// TODO Implement this library.
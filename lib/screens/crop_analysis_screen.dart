import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/ai_services.dart';

class CropAnalysisScreen extends StatefulWidget {
  const CropAnalysisScreen({Key? key}) : super(key: key);

  @override
  _CropAnalysisScreenState createState() => _CropAnalysisScreenState();
}

class _CropAnalysisScreenState extends State<CropAnalysisScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  Map<String, dynamic>? _analysisResult;
  bool _isAnalyzing = false;
  String? _error;

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        _analyzeImage(File(image.path));
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        _analyzeImage(File(image.path));
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImage(File image) async {
    setState(() {
      _selectedImage = image;
      _isAnalyzing = true;
      _analysisResult = null;
      _error = null;
    });

    try {
      final result = await AIServices.analyzeCropImage(image);

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      if (result['isCropDetected'] == false) {
        _showError('No crop detected in the image. Please try with a clearer photo.');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _error = e.toString();
      });
      _showError('Analysis failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _clearAnalysis() {
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
      _error = null;
    });
  }

  Widget _buildImagePreview() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (_isAnalyzing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Analyzing Crop...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'AI is examining your crop image',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Clear button
          Positioned(
            top: 12,
            right: 12,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _clearAnalysis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    if (_analysisResult == null) return const SizedBox();

    final identifiedCrop = _analysisResult!['identifiedCrop'];
    final confidence = _analysisResult!['confidence'] ?? 0.0;
    final quality = _analysisResult!['quality'] ?? 'unknown';
    final isCropDetected = _analysisResult!['isCropDetected'] ?? false;

    if (!isCropDetected) {
      return Card(
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'No Crop Detected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _analysisResult!['error'] ?? 'Please try with a clearer image of the crop.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Main Result Card
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(Icons.verified, size: 48, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  identifiedCrop ?? 'Unknown Crop',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crop Identified',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Details Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analysis Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Confidence Level',
                  '${(confidence * 100).toStringAsFixed(1)}%',
                  _getConfidenceColor(confidence),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Quality Assessment',
                  _capitalizeFirst(quality),
                  _getQualityColor(quality),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Detection Status',
                  'Crop Identified',
                  Colors.green,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quality Tips based on assessment
        if (quality != 'unknown') _buildQualityTips(quality),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQualityTips(String quality) {
    Map<String, Map<String, dynamic>> qualityTips = {
      'high': {
        'color': Colors.green,
        'tips': [
          'Excellent quality crop',
          'Suitable for premium markets',
          'Good shelf life expected',
          'High market value'
        ],
      },
      'medium': {
        'color': Colors.orange,
        'tips': [
          'Good quality crop',
          'Suitable for regular markets',
          'Average shelf life',
          'Competitive pricing recommended'
        ],
      },
      'low': {
        'color': Colors.red,
        'tips': [
          'Needs improvement',
          'Consider local markets',
          'Limited shelf life',
          'Quick sale recommended'
        ],
      },
    };

    final tips = qualityTips[quality] ?? qualityTips['medium']!;

    return Card(
      color: tips['color'].withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: tips['color']),
                const SizedBox(width: 8),
                Text(
                  'Quality Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tips['color'],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(tips['tips'] as List<String>).map((tip) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 16, color: tips['color']),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'high': return Colors.green;
      case 'medium': return Colors.orange;
      case 'low': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _buildImageSelectionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickImageFromCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text(
              'Take Photo with Camera',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickImageFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text(
              'Choose from Gallery',
              style: TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.green),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Analysis'),
        backgroundColor: Colors.green,
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _clearAnalysis,
              tooltip: 'Clear Analysis',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'AI-Powered Crop Analysis',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Take a photo of your crop to get instant analysis including crop identification, quality assessment, and market insights.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Image Preview or Selection Buttons
              if (_selectedImage != null)
                _buildImagePreview()
              else
                Column(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No image selected',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),

              // Analysis Results or Image Selection
              if (_selectedImage != null && !_isAnalyzing)
                _buildAnalysisResults()
              else if (_selectedImage == null)
                _buildImageSelectionButtons(),

              // Error Display
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Tips Section
              if (_selectedImage == null) ...[
                const SizedBox(height: 40),
                const Text(
                  'Tips for Best Results:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTipItem(
                  Icons.photo_camera,
                  'Good Lighting',
                  'Take photos in natural daylight for best results',
                ),
                _buildTipItem(
                  Icons.crop_free,
                  'Clear Focus',
                  'Ensure the crop is clearly visible and in focus',
                ),
                _buildTipItem(
                  Icons.aspect_ratio,
                  'Close-up Shots',
                  'Take close-up photos of the crop for better analysis',
                ),
                _buildTipItem(
                  Icons.cleaning_services,
                  'Clean Background',
                  'Use a plain background to avoid confusion',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up resources if needed
    super.dispose();
  }
}// TODO Implement this library.
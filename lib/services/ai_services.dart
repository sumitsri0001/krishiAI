import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIServices {
  static final ImageLabeler imageLabeler = GoogleMlKit.vision.imageLabeler();

  // Price Prediction
  static Future<Map<String, dynamic>> getPriceSuggestion({
    required String crop,
    required String location,
    String quality = 'medium',
    int quantity = 1,
  }) async {
    try {
      final apiUrl = dotenv.get('PRICE_PREDICTION_API_URL',
          fallback: 'http://localhost:5000');

      final response = await http.post(
        Uri.parse('$apiUrl/predict-price'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'crop': crop.toLowerCase(),
          'location': location,
          'season': _getCurrentSeason(),
          'quality': quality.toLowerCase(),
          'quantity': quantity,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return _getFallbackPrice(crop, location);
      }
    } catch (e) {
      return _getFallbackPrice(crop, location);
    }
  }

  // Image Analysis for Crop Identification
  static Future<Map<String, dynamic>> analyzeCropImage(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);

      // Filter for agricultural products
      final cropLabels = labels.where((label) =>
          _isCropRelated(label.label.toLowerCase())).toList();

      if (cropLabels.isNotEmpty) {
        final topLabel = cropLabels.first;
        return {
          'identifiedCrop': _mapToCropName(topLabel.label),
          'confidence': topLabel.confidence,
          'quality': _estimateQuality(labels),
          'isCropDetected': true,
          'error': null,
        };
      } else {
        return {
          'identifiedCrop': null,
          'confidence': 0.0,
          'quality': 'unknown',
          'isCropDetected': false,
          'error': 'No crop detected in image',
        };
      }
    } catch (e) {
      return {
        'identifiedCrop': null,
        'confidence': 0.0,
        'quality': 'unknown',
        'isCropDetected': false,
        'error': e.toString(),
      };
    }
  }

  // Helper Methods
  static bool _isCropRelated(String label) {
    final cropKeywords = [
      'tomato', 'potato', 'onion', 'carrot', 'vegetable', 'fruit',
      'wheat', 'rice', 'corn', 'apple', 'banana', 'orange', 'spinach',
      'lettuce', 'cabbage', 'broccoli', 'cauliflower', 'brinjal', 'chilli'
    ];
    return cropKeywords.any((keyword) => label.contains(keyword));
  }

  static String _mapToCropName(String label) {
    final cropMapping = {
      'tomato': 'Tomato', 'potato': 'Potato', 'onion': 'Onion',
      'carrot': 'Carrot', 'wheat': 'Wheat', 'rice': 'Rice',
      'corn': 'Corn', 'apple': 'Apple', 'banana': 'Banana',
      'orange': 'Orange', 'spinach': 'Spinach', 'lettuce': 'Lettuce',
      'cabbage': 'Cabbage', 'broccoli': 'Broccoli', 'cauliflower': 'Cauliflower',
    };
    return cropMapping[label.toLowerCase()] ?? label;
  }

  static String _estimateQuality(List<ImageLabel> labels) {
    final hasFresh = labels.any((label) =>
        label.label.toLowerCase().contains('fresh'));
    final hasRipe = labels.any((label) =>
        label.label.toLowerCase().contains('ripe'));
    final hasRotten = labels.any((label) =>
        label.label.toLowerCase().contains('rotten'));

    if (hasRotten) return 'low';
    if (hasFresh && hasRipe) return 'high';
    return 'medium';
  }

  static String _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'summer';
    if (month >= 6 && month <= 9) return 'monsoon';
    return 'winter';
  }

  static Map<String, dynamic> _getFallbackPrice(String crop, String location) {
    final basePrices = {
      'tomato': 25.0, 'potato': 15.0, 'onion': 30.0,
      'wheat': 20.0, 'rice': 35.0, 'carrot': 40.0,
      'spinach': 20.0, 'cauliflower': 25.0, 'cabbage': 18.0,
    };

    final basePrice = basePrices[crop.toLowerCase()] ?? 20.0;

    return {
      'min_price': basePrice * 0.7,
      'suggested_price': basePrice,
      'max_price': basePrice * 1.3,
      'market_avg': basePrice,
      'confidence': 0.5,
    };
  }

  static void dispose() {
    imageLabeler.close();
  }
}
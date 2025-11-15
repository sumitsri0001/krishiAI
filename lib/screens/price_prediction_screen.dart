import 'package:flutter/material.dart';
import '../services/ai_services.dart';

class PricePredictionScreen extends StatefulWidget {
  const PricePredictionScreen({Key? key}) : super(key: key);

  @override
  _PricePredictionScreenState createState() => _PricePredictionScreenState();
}

class _PricePredictionScreenState extends State<PricePredictionScreen> {
  final List<String> crops = [
    'Tomato', 'Potato', 'Onion', 'Carrot', 'Wheat', 'Rice',
    'Spinach', 'Cauliflower', 'Cabbage', 'Brinjal', 'Chilli'
  ];

  final List<String> locations = [
    'Punjab', 'Haryana', 'Uttar Pradesh', 'Maharashtra', 'Karnataka'
  ];

  final List<String> qualities = ['Low', 'Medium', 'High', 'Organic'];

  String _selectedCrop = 'Tomato';
  String _selectedLocation = 'Punjab';
  String _selectedQuality = 'Medium';
  int _quantity = 100;

  Map<String, dynamic>? _pricePrediction;
  bool _isLoading = false;

  Future<void> _getPricePrediction() async {
    setState(() {
      _isLoading = true;
      _pricePrediction = null;
    });

    try {
      final prediction = await AIServices.getPriceSuggestion(
        crop: _selectedCrop,
        location: _selectedLocation,
        quality: _selectedQuality,
        quantity: _quantity,
      );

      setState(() {
        _pricePrediction = prediction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prediction failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Price Prediction'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Get AI-powered price suggestions for your crops',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Crop Selection
              _buildDropdown(
                label: 'Select Crop',
                value: _selectedCrop,
                items: crops,
                onChanged: (value) => setState(() => _selectedCrop = value!),
              ),
              const SizedBox(height: 16),

              // Location Selection
              _buildDropdown(
                label: 'Select Location',
                value: _selectedLocation,
                items: locations,
                onChanged: (value) => setState(() => _selectedLocation = value!),
              ),
              const SizedBox(height: 16),

              // Quality Selection
              _buildDropdown(
                label: 'Select Quality',
                value: _selectedQuality,
                items: qualities,
                onChanged: (value) => setState(() => _selectedQuality = value!),
              ),
              const SizedBox(height: 16),

              // Quantity Input
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity (kg)',
                  border: const OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                onChanged: (value) {
                  setState(() {
                    _quantity = int.tryParse(value) ?? 100;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Predict Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _getPricePrediction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text(
                    'Get Price Prediction',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Results
              if (_pricePrediction != null) _buildPriceResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(item),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceResults() {
    final suggestedPrice = _pricePrediction!['suggested_price']?.toDouble() ?? 0.0;
    final minPrice = _pricePrediction!['min_price']?.toDouble() ?? 0.0;
    final maxPrice = _pricePrediction!['max_price']?.toDouble() ?? 0.0;
    final marketAvg = _pricePrediction!['market_avg']?.toDouble() ?? 0.0;
    final confidence = _pricePrediction!['confidence']?.toDouble() ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Price Prediction Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Suggested Price
            Center(
              child: Column(
                children: [
                  Text(
                    '₹${suggestedPrice.toStringAsFixed(2)}/kg',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AI Suggested Price',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Price Range
            _buildPriceRangeItem('Minimum Price', minPrice, Colors.red),
            _buildPriceRangeItem('Maximum Price', maxPrice, Colors.green),
            const SizedBox(height: 16),

            // Market Comparison
            Row(
              children: [
                Icon(
                  suggestedPrice > marketAvg ?
                  Icons.arrow_upward : Icons.arrow_downward,
                  color: suggestedPrice > marketAvg ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your price is ${suggestedPrice > marketAvg ? 'above' : 'below'} '
                        'market average (₹${marketAvg.toStringAsFixed(2)})',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Confidence
            LinearProgressIndicator(
              value: confidence,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                confidence > 0.7 ? Colors.green :
                confidence > 0.4 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeItem(String label, double price, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '₹${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}// TODO Implement this library.
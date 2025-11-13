import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'smart_listing_screen.dart';
import 'price_prediction_screen.dart';
import 'crop_analysis_screen.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({Key? key}) : super(key: key);

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _productController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await dotenv.load();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Farmer Dashboard"),
        actions: [
          // AI Tools Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.auto_awesome),
            onSelected: (value) {
              switch (value) {
                case 'price_prediction':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PricePredictionScreen()),
                  );
                  break;
                case 'crop_analysis':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CropAnalysisScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'price_prediction',
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Price Prediction'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'crop_analysis',
                child: Row(
                  children: [
                    Icon(Icons.photo_camera, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Crop Analysis'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      backgroundColor: Colors.green.shade50,
      body: Column(
        children: [
          // AI Features Quick Access
          _buildAIFeaturesSection(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('products')
                  .where('farmerId', isEqualTo: user?.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data?.docs ?? [];

                if (products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No products listed yet.\nUse Smart Listing to add your first product!",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(product);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Smart Listing FAB
          FloatingActionButton(
            heroTag: "smart_listing",
            backgroundColor: Colors.blue,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SmartListingScreen()),
              );
            },
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(height: 16),
          // Traditional Add Product FAB
          FloatingActionButton.extended(
            heroTag: "add_product",
            backgroundColor: Colors.green.shade700,
            icon: const Icon(Icons.add),
            label: const Text("Add Product"),
            onPressed: () => _showAddProductDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAIFeaturesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI-Powered Tools",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAIFeatureButton(
                  icon: Icons.auto_awesome,
                  title: "Smart Listing",
                  subtitle: "AI-assisted product listing",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SmartListingScreen()),
                    );
                  },
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAIFeatureButton(
                  icon: Icons.attach_money,
                  title: "Price Predict",
                  subtitle: "Get optimal pricing",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PricePredictionScreen()),
                    );
                  },
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIFeatureButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(DocumentSnapshot product) {
    final hasAISuggestion = product['ai_suggested_price'] != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasAISuggestion ? Colors.blue.shade100 : Colors.green.shade100,
          child: Icon(
            hasAISuggestion ? Icons.auto_awesome : Icons.local_florist,
            color: hasAISuggestion ? Colors.blue : Colors.green,
          ),
        ),
        title: Text(
          product['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("₹${product['price']} per kg"),
            if (hasAISuggestion)
              Text(
                "AI Suggested: ₹${product['ai_suggested_price']}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            await _firestore
                .collection('products')
                .doc(product.id)
                .delete();
          },
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _productController,
              decoration: const InputDecoration(
                labelText: "Product Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Price per kg",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            child: const Text("Save"),
            onPressed: () async {
              final name = _productController.text.trim();
              final price = _priceController.text.trim();

              if (name.isNotEmpty && price.isNotEmpty) {
                await _firestore.collection('products').add({
                  'name': name,
                  'price': double.parse(price),
                  'farmerId': _auth.currentUser?.uid,
                  'timestamp': FieldValue.serverTimestamp(),
                  'category': 'General',
                  'quality': 'Medium',
                });
                _productController.clear();
                _priceController.clear();
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
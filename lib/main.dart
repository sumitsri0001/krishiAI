import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/farmer_dashboard.dart';
import 'screens/buyer_dashboard.dart';
import 'screens/chat_screen.dart';
import 'screens/smart_listing_screen.dart';
import 'screens/price_prediction_screen.dart';
import 'screens/crop_analysis_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DirectMarketApp());
}
class DirectMarketApp extends StatelessWidget {
  const DirectMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Direct Market Access',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      // Default route (login)
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/farmer': (context) => const FarmerDashboard(),
        '/buyer': (context) => const BuyerDashboard(),
        '/chat': (context) => const ChatScreen(),
        '/smart_listing': (context) => const SmartListingScreen(),
        '/price_prediction': (context) => const PricePredictionScreen(),
        '/crop_analysis': (context) => const CropAnalysisScreen(),
      },
    );
  }
}

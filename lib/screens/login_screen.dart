import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'complete_profile_screen.dart';
import 'farmer_dashboard.dart';
import 'buyer_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool isLoading = false;
  bool _isImageLoading = true;
  bool _hasImageError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      testFirestoreConnection();
    });
  }

  // Test Firestore connection
  void testFirestoreConnection() async {
    print('🧪 Testing Firestore connection...');

    try {
      // Test 1: Simple write
      final testDoc = await FirebaseFirestore.instance
          .collection('debug_tests')
          .add({
        'test_name': 'Connection Test',
        'timestamp': FieldValue.serverTimestamp(),
        'app_version': '1.0.0',
      });

      print('✅ Write test PASSED - Document ID: ${testDoc.id}');

      // Test 2: Read back
      final snapshot = await testDoc.get();
      print('✅ Read test PASSED - Data: ${snapshot.data()}');

      // Test 3: Query test
      final querySnapshot = await FirebaseFirestore.instance
          .collection('debug_tests')
          .limit(1)
          .get();

      print('✅ Query test PASSED - Found ${querySnapshot.docs.length} documents');

    } catch (e) {
      print('❌ Firestore test FAILED: $e');
      print('📋 Full error details:');
      print(e);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated Background
              _buildAnimatedBackground(),

              Center(
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Header with Animations
                        _buildAppHeader().animate().fadeIn(duration: 600.ms).slideY(begin: -0.5, end: 0),

                        const SizedBox(height: 40),

                        // Phone Input Section
                        _buildPhoneInputSection().animate().fadeIn(delay: 200.ms).slideX(begin: -20, end: 0),

                        const SizedBox(height: 30),

                        // OTP Button
                        _buildOtpButton().animate().fadeIn(delay: 400.ms).slideY(begin: 20, end: 0),

                        const SizedBox(height: 25),

                        // Divider
                        _buildDivider().animate().fadeIn(delay: 600.ms),

                        const SizedBox(height: 25),

                        // Google Sign In Button
                        _buildGoogleSignInButton().animate().fadeIn(delay: 800.ms).slideY(begin: 20, end: 0),

                        const SizedBox(height: 20),

                        // Footer Text
                        _buildFooterText().animate().fadeIn(delay: 1000.ms),
                      ],
                    ),
                  ),
                ),
              ),

              // Loading Overlay
              if (isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Floating animated elements
        Positioned(
          top: 100,
          left: 30,
          child: Icon(Icons.eco, color: Colors.white.withOpacity(0.1), size: 40)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 0.8, end: 1.2, duration: 3000.ms),
        ),
        Positioned(
          top: 200,
          right: 40,
          child: Icon(Icons.agriculture, color: Colors.white.withOpacity(0.1), size: 35)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 0.7, end: 1.3, duration: 2500.ms),
        ),
        Positioned(
          bottom: 150,
          left: 50,
          child: Icon(Icons.spa, color: Colors.white.withOpacity(0.1), size: 30)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 0.6, end: 1.4, duration: 4000.ms),
        ),
      ],
    );
  }

  Widget _buildAppHeader() {
    return Column(
      children: [
        // Logo with animation and proper image handling
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: _hasImageError
                ? _buildFallbackLogo()
                : Image.asset(
              'assets/images/login_screen_photo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Set error state and show fallback
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_hasImageError) {
                    setState(() {
                      _hasImageError = true;
                    });
                  }
                });
                return _buildFallbackLogo();
              },
            ),
          ),
        )
            .animate()
            .scale(duration: 800.ms, curve: Curves.elasticOut)
            .then(delay: 200.ms)
            .shake(duration: 600.ms, hz: 2),

        const SizedBox(height: 25),
        const Text(
          "KrashiAI",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.green,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Direct Market Access for Farmers",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      color: Colors.green,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              size: 40,
              color: Colors.white,
            ),
            SizedBox(height: 4),
            Text(
              "KrashiAI",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Enter your phone number",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              // Country Code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                ),
                child: const Row(
                  children: [
                    Text("🇮🇳", style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      "+91",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Phone Input Field
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: "Enter your phone number",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpButton() {
    final isValid = _phoneController.text.length == 10;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isValid && !isLoading ? _verifyPhone : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? Colors.green : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          minimumSize: const Size(double.infinity, 56),
          elevation: 5,
        ),
        icon: const Icon(Icons.phone_android),
        label: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Text(
          "Continue with OTP",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "OR",
            style: TextStyle(
              color: Colors.grey.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google logo with better error handling
            Container(
              width: 24,
              height: 24,
              child: Image.asset(
                'assets/images/google_logo.jpeg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.g_mobiledata, size: 24, color: Colors.red);
                },
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Continue with Google",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterText() {
    return Column(
      children: [
        Text(
          "By continuing, you agree to our",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                // Handle Terms of Service
              },
              child: Text(
                "Terms of Service",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              " and ",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.withOpacity(0.7),
              ),
            ),
            GestureDetector(
              onTap: () {
                // Handle Privacy Policy
              },
              child: Text(
                "Privacy Policy",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.green),
              ),
              const SizedBox(height: 16),
              Text(
                "Please wait...",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- OTP AUTHENTICATION -----------------
  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showErrorSnackbar("Please enter a valid 10-digit phone number");
      return;
    }

    setState(() => isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted: (credential) async {
          try {
            await _auth.signInWithCredential(credential);
            await _handlePostLogin();
          } catch (e) {
            if (mounted) {
              setState(() => isLoading = false);
            }
            _showErrorSnackbar("Auto-verification failed: ${e.toString()}");
          }
        },
        verificationFailed: (error) {
          if (mounted) {
            setState(() => isLoading = false);
          }
          _showErrorSnackbar("Verification failed: ${error.message}");
        },
        codeSent: (verificationId, resendToken) {
          if (mounted) {
            setState(() => isLoading = false);
          }
          _showOtpDialog(verificationId);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (mounted) {
            setState(() => isLoading = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      _showErrorSnackbar("Phone verification error: ${e.toString()}");
    }
  }

  void _showOtpDialog(String verificationId) {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Enter OTP"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "We've sent a 6-digit code to your phone",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  maxLength: 6,
                  decoration: const InputDecoration(
                    counterText: "",
                    border: OutlineInputBorder(),
                    hintText: "000000",
                  ),
                ),
                if (isVerifying) ...[
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isVerifying ? null : () async {
                  final otp = otpController.text.trim();
                  if (otp.length != 6) {
                    _showErrorSnackbar("Please enter a 6-digit code");
                    return;
                  }

                  setDialogState(() => isVerifying = true);

                  try {
                    final credential = PhoneAuthProvider.credential(
                      verificationId: verificationId,
                      smsCode: otp,
                    );

                    await _auth.signInWithCredential(credential);

                    if (mounted) {
                      Navigator.pop(context);
                      await _handlePostLogin();
                    }
                  } catch (e) {
                    setDialogState(() => isVerifying = false);
                    _showErrorSnackbar("Invalid OTP. Please try again.");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: isVerifying
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text("Verify", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- GOOGLE SIGN-IN -----------------
  Future<void> _signInWithGoogle() async {
    try {
      setState(() => isLoading = true);

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credentials
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with credentials
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      print("Google Sign-In Successful: ${userCredential.user?.email}");

      await _handlePostLogin();

    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      print("Google Sign-In Error: $e");
      _showErrorSnackbar("Google Sign-In failed: ${e.toString()}");
    }
  }

  // ---------------- POST LOGIN HANDLING -----------------
  Future<void> _handlePostLogin() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        _showErrorSnackbar("Authentication failed");
        return;
      }

      print('🔐 User authenticated: ${user.uid}');
      print('📧 User email: ${user.email}');
      print('📞 User phone: ${user.phoneNumber}');
      print('👤 User display name: ${user.displayName}');
      print('🖼️ User photo URL: ${user.photoURL}');

      // Check if user has complete profile in Firestore
      try {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 10));

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          print('📄 User document data: $userData');

          // Check if profile is complete (has name, gender, age, and role)
          final bool hasCompleteProfile = userData != null &&
              userData.containsKey('name') &&
              userData.containsKey('gender') &&
              userData.containsKey('age') &&
              userData.containsKey('role') &&
              userData['name'] != null &&
              userData['gender'] != null &&
              userData['age'] != null &&
              userData['role'] != null;

          if (hasCompleteProfile) {
            // User has complete profile and role, navigate to dashboard
            final String role = userData!['role'];
            print('✅ User has complete profile, role: $role');

            if (mounted) {
              setState(() => isLoading = false);
              if (role == 'farmer') {
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
            }
            return;
          } else {
            print('ℹ️ User profile incomplete, redirecting to complete profile');
          }
        } else {
          print('ℹ️ No user document found, redirecting to complete profile');
        }
      } catch (e) {
        print('⚠️ Error checking user profile: $e');
        // Continue to profile setup even if there's an error
      }

      // If profile is incomplete or doesn't exist, go to complete profile screen
      if (mounted) {
        setState(() => isLoading = false);

        // Determine if it's Google sign-in
        final isGoogleSignIn = user.providerData.any((profile) => profile.providerId == 'google.com');
        print('🔍 Sign-in method: ${isGoogleSignIn ? 'Google' : 'Phone'}');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(
              isGoogleSignIn: isGoogleSignIn,
              googleName: user.displayName,
              googleProfilePicture: user.photoURL,
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      print("❌ Post-login error: $e");

      // Even if there's an error, proceed to complete profile
      final user = _auth.currentUser;
      if (mounted && user != null) {
        final isGoogleSignIn = user.providerData.any((profile) => profile.providerId == 'google.com');

        _showSuccessSnackbar("Login successful! Please complete your profile.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(
              isGoogleSignIn: isGoogleSignIn,
              googleName: user.displayName,
              googleProfilePicture: user.photoURL,
            ),
          ),
        );
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
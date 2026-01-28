import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'name_screen.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Sign in anonymously
      await _firebaseService.signInAnonymously();

      // Wait a bit for Firebase to stabilize
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Check if user has a name
      final hasName = await _firebaseService.hasUserName();

      if (!mounted) return;

      if (hasName) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NameScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Show error but let user continue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Initialization error: $e')),
      );

      // Redirect to name screen anyway
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NameScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '👍 Press Me App',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
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
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Sign in anonymously if needed
      await _firebaseService.signInAnonymously();

      // Check if user has a name
      final hasName = await _firebaseService.hasUserName();

      if (!mounted) return;

      if (!hasName) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NameScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
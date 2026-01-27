import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthCheck(),
    );
  }
}

// 🔐 Check if user is logged in and has a name
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    // Sign in anonymously if not already
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    // Check if user has a stored name
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName');

    if (!mounted) return;

    if (userName == null) {
      // First time - ask for name
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NameInputScreen()),
      );
    } else {
      // Already has name - go to main app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LikePage()),
      );
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

// 📝 Screen to ask for user's name (ONLY FIRST TIME)
class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user UID
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final name = _nameController.text.trim();

      // Save name to shared preferences (local)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);

      // Save user profile to Firebase
      await FirebaseDatabase.instance.ref('users/$uid/profile').set({
        'name': name,
        'likes': 0,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Also initialize totalLikes if it doesn't exist
      final totalRef = FirebaseDatabase.instance.ref('totalLikes');
      final snapshot = await totalRef.get();
      if (!snapshot.exists) {
        await totalRef.set(0);
      }

      if (!mounted) return;

      // Go to main app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LikePage()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Welcome! 👋")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "What's your name?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveName,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🏠 Main App Screen
class LikePage extends StatefulWidget {
  const LikePage({super.key});

  @override
  State<LikePage> createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  static const platform = MethodChannel('com.example.press_me_app/audio');

  late String _uid;
  late String _userName;
  int _userLikes = 0;
  int _totalLikes = 0;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    // Get UID
    _uid = FirebaseAuth.instance.currentUser!.uid;

    // Get name from shared preferences
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName') ?? 'User';

    // Listen to user's likes
    FirebaseDatabase.instance.ref('users/$_uid/profile/likes').onValue.listen(
      (event) {
        if (mounted) {
          setState(() {
            _userLikes = (event.snapshot.value as int?) ?? 0;
          });
        }
      },
    );

    // Listen to total likes
    FirebaseDatabase.instance.ref('totalLikes').onValue.listen(
      (event) {
        if (mounted) {
          setState(() {
            _totalLikes = (event.snapshot.value as int?) ?? 0;
          });
        }
      },
    );
  }

  Future<void> _incrementLikes() async {
    try {
      // Increment user's likes
      await FirebaseDatabase.instance
          .ref('users/$_uid/profile/likes')
          .set(_userLikes + 1);

      // Increment total likes
      await FirebaseDatabase.instance
          .ref('totalLikes')
          .set(_totalLikes + 1);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Mute all sounds
  Future<void> _muteDevice() async {
    try {
      await platform.invokeMethod('muteAudio');
      setState(() => _isMuted = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔇 Device Muted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on PlatformException catch (e) {
      print('Error muting device: ${e.message}');
    }
  }

  // Unmute device
  Future<void> _unmuteDevice() async {
    try {
      await platform.invokeMethod('unmuteAudio');
      setState(() => _isMuted = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔊 Device Unmuted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on PlatformException catch (e) {
      print('Error unmuting device: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Press Me App"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Hi, $_userName! 👋',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🌍 Global likes counter
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Text(
                    '🌍 Global Likes',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_totalLikes',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 👤 User likes counter
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Text(
                    '👤 Your Likes',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_userLikes',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Press me button
            ElevatedButton.icon(
              onPressed: _incrementLikes,
              icon: const Icon(Icons.thumb_up),
              label: const Text("Press me"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: Colors.blue,
              ),
            ),

            const SizedBox(height: 40),

            // Mute and Unmute buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isMuted ? null : _muteDevice,
                  icon: const Icon(Icons.volume_off),
                  label: const Text("Mute"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMuted ? Colors.grey : Colors.red,
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _isMuted ? _unmuteDevice : null,
                  icon: const Icon(Icons.volume_up),
                  label: const Text("Unmute"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMuted ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),

            // Status indicator
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isMuted ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isMuted ? '🔇 Device is MUTED' : '🔊 Device is UNMUTED',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isMuted ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
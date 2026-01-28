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
      home: SplashScreen(),
    );
  }
}

// Splash/Auth Check Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Sign in anonymously if needed
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      // Check shared preferences for name
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName');

      if (!mounted) return;

      if (userName == null) {
        // Go to name input
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NameScreen()),
        );
      } else {
        // Go to main app
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

// Name Input Screen
class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
  if (_controller.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter your name')),
    );
    return;
  }

  setState(() => _loading = true);

  try {
    final name = _controller.text.trim();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 1. Update Firebase Auth display name FIRST
    await FirebaseAuth.instance.currentUser!.updateDisplayName(name);

    // 2. Reload to ensure it's saved
    await FirebaseAuth.instance.currentUser!.reload();

    // 3. Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);

    // 4. Save to database
    await FirebaseDatabase.instance.ref('users/$uid').set({
      'name': name,
      'likes': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    // 5. Initialize total likes
    final totalRef = FirebaseDatabase.instance.ref('totalLikes');
    final snapshot = await totalRef.get();
    if (!snapshot.exists) {
      await totalRef.set(0);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  } catch (e) {
    print('Error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'What\'s your name?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Enter name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
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

// Main Home Screen
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = MethodChannel('com.example.press_me_app/audio');

  late String _uid;
  String _userName = 'User';
  int _userLikes = 0;
  int _totalLikes = 0;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _uid = FirebaseAuth.instance.currentUser!.uid;

    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName') ?? 'User';

    // Listen to user likes
    FirebaseDatabase.instance.ref('users/$_uid/likes').onValue.listen((e) {
      if (mounted && e.snapshot.exists) {
        setState(() => _userLikes = (e.snapshot.value as int?) ?? 0);
      }
    });

    // Listen to total likes
    FirebaseDatabase.instance.ref('totalLikes').onValue.listen((e) {
      if (mounted && e.snapshot.exists) {
        setState(() => _totalLikes = (e.snapshot.value as int?) ?? 0);
      }
    });
  }

  Future<void> _addLike() async {
    try {
      await FirebaseDatabase.instance
          .ref('users/$_uid/likes')
          .set(_userLikes + 1);

      await FirebaseDatabase.instance
          .ref('totalLikes')
          .set(_totalLikes + 1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _mute() async {
  try {
    final result = await platform.invokeMethod('muteAudio');
    print('Mute result: $result');
    
    setState(() => _muted = true);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔇 Muted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } on PlatformException catch (e) {
    print('Mute error: ${e.code} - ${e.message}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mute error: ${e.message}')),
      );
    }
  }
}

Future<void> _unmute() async {
  try {
    final result = await platform.invokeMethod('unmuteAudio');
    print('Unmute result: $result');
    
    setState(() => _muted = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 Unmuted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } on PlatformException catch (e) {
    print('Unmute error: ${e.code} - ${e.message}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unmute error: ${e.message}')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Press Me App'),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hi, $_userName! 👋',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text('🌍 Global Likes'),
                    Text(
                      '$_totalLikes',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text('👤 Your Likes'),
                    Text(
                      '$_userLikes',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _addLike,
                icon: const Icon(Icons.thumb_up),
                label: const Text('Press me'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _muted ? null : _mute,
                    icon: const Icon(Icons.volume_off),
                    label: const Text('Mute'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _muted ? Colors.grey : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _muted ? _unmute : null,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Unmute'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _muted ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
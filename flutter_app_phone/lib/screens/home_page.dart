import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import 'package:permission_handler/permission_handler.dart';  // Add this!
import 'settings_screen.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = MethodChannel('com.example.press_me_app/audio');

  late String _userName = 'User';
  int _userLikes = 0;
  int _totalLikes = 0;
  bool _muted = false;
  final _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _setupListeners();
  }

  // Load user name WITHOUT setState in async gap
  Future<void> _loadUserName() async {
    final userName = await _firebaseService.getUserName();
    if (mounted) {
      setState(() {
        _userName = userName;
      });
    }
  }

  // Setup listeners AFTER loading
  void _setupListeners() {
    _firebaseService.getUserLikesStream().listen((likes) {
      if (mounted) {
        setState(() => _userLikes = likes);
      }
    });

    _firebaseService.getTotalLikesStream().listen((likes) {
      if (mounted) {
        setState(() => _totalLikes = likes);
      }
    });
  }

  Future<void> _addLike() async {
    try {
      await _firebaseService.addUserLike(_userLikes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }


Future<void> _mute() async {
  try {
    // Request permission first
    final status = await Permission.accessNotificationPolicy.request();
    
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Permission denied. Please enable in Settings'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Now mute
    await platform.invokeMethod('muteAudio');
    if (mounted) {
      setState(() => _muted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔇 Muted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } on PlatformException catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mute error: ${e.message}')),
      );
    }
  }
}

Future<void> _unmute() async {
  try {
    // Request permission first
    final status = await Permission.accessNotificationPolicy.request();
    
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Permission denied. Please enable in Settings'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Now unmute
    await platform.invokeMethod('unmuteAudio');
    if (mounted) {
      setState(() => _muted = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 Unmuted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } on PlatformException catch (e) {
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
        actions: [
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
    ),
  ],
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
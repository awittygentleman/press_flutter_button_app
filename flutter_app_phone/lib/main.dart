import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> signInAnonymously() async {
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await signInAnonymously();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LikePage(),
    );
  }
}

class LikePage extends StatefulWidget {
  const LikePage({super.key});

  @override
  State<LikePage> createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  final DatabaseReference _likesRef =
      FirebaseDatabase.instance.ref('likes');
  
  static const platform = MethodChannel('com.example.press_me_app/audio');

  int likes = 0;
  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    _likesRef.onValue.listen((event) {
      final value = event.snapshot.value;
      if (value != null) {
        setState(() {
          likes = value as int;
        });
      }
    });
  }

  void incrementLike() {
    _likesRef.set(likes + 1);
  }

  // Mute all sounds
  Future<void> muteDevice() async {
    try {
      await platform.invokeMethod('muteAudio');
      setState(() {
        isMuted = true;
      });
      
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
  Future<void> unmuteDevice() async {
    try {
      await platform.invokeMethod('unmuteAudio');
      setState(() {
        isMuted = false;
      });
      
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
      appBar: AppBar(title: const Text("Press Me App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Likes counter
            Text("👍 $likes", style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 20),
            
            // Press me button
            ElevatedButton(
              onPressed: incrementLike,
              child: const Text("Press me"),
            ),
            
            const SizedBox(height: 40),
            
            // Mute and Unmute buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mute button
                ElevatedButton.icon(
                  onPressed: isMuted ? null : muteDevice,
                  icon: const Icon(Icons.volume_off),
                  label: const Text("Mute"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMuted ? Colors.grey : Colors.red,
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Unmute button
                ElevatedButton.icon(
                  onPressed: isMuted ? unmuteDevice : null,
                  icon: const Icon(Icons.volume_up),
                  label: const Text("Unmute"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMuted ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            
            // Status indicator
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isMuted ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isMuted ? '🔇 Device is MUTED' : '🔊 Device is UNMUTED',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isMuted ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
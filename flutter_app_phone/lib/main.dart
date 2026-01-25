import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
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

  int likes = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Press Me App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("👍 $likes", style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: incrementLike,
              child: const Text("Press me"),
            ),
          ],
        ),
      ),
    );
  }
}

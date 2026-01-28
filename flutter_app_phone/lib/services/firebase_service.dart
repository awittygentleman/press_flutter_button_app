import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  // ============================================
  // 🔐 AUTHENTICATION METHODS
  // ============================================

  /// Sign in anonymously
  Future<void> signInAnonymously() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      // Silent fail - continue anyway
      rethrow;
    }
  }

  /// Get current user UID
  String get currentUserUid {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  /// Check if user has a name
  Future<bool> hasUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') != null;
  }

  /// Get user name from local storage
  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? 'User';
  }

  // ============================================
  // 👤 USER REGISTRATION
  // ============================================

  /// Save user name to Firebase Auth, local storage, and database
  Future<void> saveUserName(String name) async {
    final uid = currentUserUid;

    // 1. Update Firebase Auth display name
    try {
      await FirebaseAuth.instance.currentUser!.updateDisplayName(name);
      await FirebaseAuth.instance.currentUser!.reload();
    } catch (authError) {
      // Continue even if auth fails - we'll save to database
    }

    // 2. Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);

    // 3. Save to database
    await FirebaseDatabase.instance.ref('users/$uid').set({
      'name': name,
      'likes': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    // 4. Initialize total likes if needed
    final totalRef = FirebaseDatabase.instance.ref('totalLikes');
    final snapshot = await totalRef.get();
    if (!snapshot.exists) {
      await totalRef.set(0);
    }
  }

  // ============================================
  // 👍 LIKES OPERATIONS
  // ============================================

  /// Add a like for current user
  Future<void> addUserLike(int currentLikes) async {
    final uid = currentUserUid;
    final newLikes = currentLikes + 1;

    await FirebaseDatabase.instance
        .ref('users/$uid/likes')
        .set(newLikes);

    // Also increment total likes
    await FirebaseDatabase.instance
        .ref('totalLikes')
        .set(await getTotalLikes() + 1);
  }

  /// Get total likes from database
  Future<int> getTotalLikes() async {
    final snapshot = await FirebaseDatabase.instance.ref('totalLikes').get();
    return (snapshot.value as int?) ?? 0;
  }

  // ============================================
  // 📡 LISTENERS (Real-time updates)
  // ============================================

  /// Listen to user's likes changes
  Stream<int> getUserLikesStream() {
    final uid = currentUserUid;
    return FirebaseDatabase.instance
        .ref('users/$uid/likes')
        .onValue
        .map((event) {
      try {
        if (event.snapshot.exists) {
          final value = event.snapshot.value;
          if (value is int) {
            return value;
          } else if (value is double) {
            return value.toInt();
          }
          return 0;
        }
        return 0;
      } catch (e) {
        return 0;
      }
    });
  }

  /// Listen to total likes changes
  Stream<int> getTotalLikesStream() {
    return FirebaseDatabase.instance
        .ref('totalLikes')
        .onValue
        .map((event) {
      try {
        if (event.snapshot.exists) {
          final value = event.snapshot.value;
          if (value is int) {
            return value;
          } else if (value is double) {
            return value.toInt();
          }
          return 0;
        }
        return 0;
      } catch (e) {
        return 0;
      }
    });
  }
}
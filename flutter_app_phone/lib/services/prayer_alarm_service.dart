import 'package:flutter/services.dart';
import 'dart:async';

class PrayerAlarmService {
  static const platform = MethodChannel('com.example.press_me_app/audio');
  static Timer? _timer;
  static bool _isMuted = false;

  /// Start monitoring prayer times
  static void startMonitoring({
    required Map<String, String> prayerTimes,
    required VoidCallback onPrayerTime,
  }) {
    // Stop existing timer
    _timer?.cancel();

    // Check every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkPrayerTimes(prayerTimes, onPrayerTime);
    });

    // Also check immediately
    _checkPrayerTimes(prayerTimes, onPrayerTime);
  }

  /// Stop monitoring
  static void stopMonitoring() {
    _timer?.cancel();
    autoUnmute();  // Unmute when stopping
  }

  /// Check if we're in prayer time window
  static void _checkPrayerTimes(
    Map<String, String> prayerTimes,
    VoidCallback onPrayerTime,
  ) {
    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    bool inPrayerWindow = false;

    for (var prayerName in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      final prayerTime = prayerTimes[prayerName] ?? '';

      if (prayerTime.isNotEmpty) {
        if (_isInPrayerWindow(currentTime, prayerTime)) {
          inPrayerWindow = true;
          if (!_isMuted) {
            _isMuted = true;
            onPrayerTime();
          }
          break;
        }
      }
    }

    // If not in prayer window but was muted, unmute
    if (!inPrayerWindow && _isMuted) {
      _isMuted = false;
      autoUnmute();
    }
  }

  /// Check if current time is within 5 minutes of prayer time
  static bool _isInPrayerWindow(String currentTime, String prayerTime) {
    try {
      final curr = _parseTime(currentTime);
      final prayer = _parseTime(prayerTime);

      final diff = prayer.difference(curr).inMinutes.abs();
      return diff <= 5; // 5 minute window
    } catch (e) {
      return false;
    }
  }

  /// Parse time string "HH:MM" to DateTime
  static DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Auto-mute when prayer time arrives
  static Future<void> autoMute() async {
    try {
      await platform.invokeMethod('muteAudio');
    } catch (e) {
      // Silent fail
    }
  }

  /// Auto-unmute after prayer time ends
  static Future<void> autoUnmute() async {
    try {
      await platform.invokeMethod('unmuteAudio');
    } catch (e) {
      // Silent fail
    }
  }
}
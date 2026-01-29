import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/prayer_times_service.dart';
import '../services/prayer_alarm_service.dart';  // Add this!


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firebaseService = FirebaseService();
  bool _loading = false;
  Map<String, String>? _prayerTimes;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  /// Load prayer times from Firebase
  Future<void> _loadPrayerTimes() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final times = await _firebaseService.getPrayerTimes(uid);
      
      if (times != null) {
        setState(() {
          _prayerTimes = times;
          _errorMessage = null;
        });
        _startMonitoring();  // ← ADD THIS LINE
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error loading prayer times');
    }
  }

  /// Start monitoring prayer times
void _startMonitoring() {
  if (_prayerTimes != null) {
    PrayerAlarmService.startMonitoring(
      prayerTimes: _prayerTimes!,
      onPrayerTime: () {
        // Auto-mute
        PrayerAlarmService.autoMute();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🤐 Auto-muted for prayer time'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }
}
  /// Fetch prayer times from location
  Future<void> _fetchPrayerTimesFromLocation() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Get location
      final position = await LocationService.getCurrentLocation();
      
      if (position == null) {
        setState(() {
          _errorMessage = '❌ Location permission denied';
          _loading = false;
        });
        return;
      }

      // Fetch prayer times from API
      final times = await PrayerTimesService.getPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Save to Firebase
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _firebaseService.savePrayerTimes(
        userId: uid,
        latitude: position.latitude,
        longitude: position.longitude,
        prayerTimes: times,
      );

      setState(() {
        _prayerTimes = times;
        _loading = false;
      });
      _startMonitoring();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Prayer times fetched and saved!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '❌ Error: ${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
void dispose() {
  PrayerAlarmService.stopMonitoring();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Settings'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prayer Times Section
            const Text(
              '🕌 Prayer Times',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),

            const SizedBox(height: 16),

            // Prayer Times Display
            if (_prayerTimes != null) ...[
              _buildPrayerTimeCard('Fajr', _prayerTimes!['fajr'] ?? '-'),
              _buildPrayerTimeCard('Dhuhr', _prayerTimes!['dhuhr'] ?? '-'),
              _buildPrayerTimeCard('Asr', _prayerTimes!['asr'] ?? '-'),
              _buildPrayerTimeCard('Maghrib', _prayerTimes!['maghrib'] ?? '-'),
              _buildPrayerTimeCard('Isha', _prayerTimes!['isha'] ?? '-'),
              const SizedBox(height: 16),
            ] else if (!_loading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '📍 No prayer times set yet.\nTap the button below to fetch from your location!',
                  style: TextStyle(fontSize: 14),
                ),
              ),

            const SizedBox(height: 24),

            // Fetch Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _fetchPrayerTimesFromLocation,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.location_on),
                label: Text(
                  _loading
                      ? 'Fetching Prayer Times...'
                      : 'Fetch Prayer Times from Location',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Refresh Button
            if (_prayerTimes != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _fetchPrayerTimesFromLocation,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Prayer Times'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build prayer time card
  Widget _buildPrayerTimeCard(String name, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
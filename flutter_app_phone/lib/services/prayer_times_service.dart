import 'package:http/http.dart' as http;
import 'dart:convert';

class PrayerTime {
  final String name;
  final String time;

  PrayerTime({required this.name, required this.time});

  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      name: json['name'],
      time: json['time'],
    );
  }
}

class PrayerTimesService {
  static const String baseUrl = 'https://api.aladhan.com/v1/timings';

  /// Fetch prayer times for a given location
  static Future<Map<String, String>> getPrayerTimes({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch ~/ 1000;

      final url =
          '$baseUrl/$timestamp?latitude=$latitude&longitude=$longitude&method=2';

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final timings = json['data']['timings'] as Map<String, dynamic>;

        // Extract the 5 main prayer times
        return {
          'fajr': timings['Fajr'] ?? '',
          'dhuhr': timings['Dhuhr'] ?? '',
          'asr': timings['Asr'] ?? '',
          'maghrib': timings['Maghrib'] ?? '',
          'isha': timings['Isha'] ?? '',
        };
      } else {
        throw Exception('Failed to fetch prayer times');
      }
    } catch (e) {
      throw Exception('Error fetching prayer times: $e');
    }
  }
}
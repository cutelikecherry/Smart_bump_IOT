
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherCondition {
  final String description;   // e.g. "light rain"
  final double visibilityM;   // meters, OpenWeatherMap default max 10000
  final bool isNight;
  final bool isRaining;
  final bool isFoggy;

  WeatherCondition({
    required this.description,
    required this.visibilityM,
    required this.isNight,
    required this.isRaining,
    required this.isFoggy,
  });


  bool get isHazardous => isRaining || isFoggy || (isNight && visibilityM < 5000);

  factory WeatherCondition.fromJson(Map<String, dynamic> json) {
    final weatherList = json['weather'] as List<dynamic>? ?? [];
    final main = weatherList.isNotEmpty ? weatherList[0]['main'] as String? ?? '' : '';
    final desc = weatherList.isNotEmpty ? weatherList[0]['description'] as String? ?? '' : '';

    final visibility = (json['visibility'] ?? 10000).toDouble();

    final sys = json['sys'] as Map<String, dynamic>? ?? {};
    final nowUtc = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sunrise = sys['sunrise'] as int? ?? 0;
    final sunset = sys['sunset'] as int? ?? 0;
    final isNight = sunrise != 0 && sunset != 0 && (nowUtc < sunrise || nowUtc > sunset);

    final rainy = main == 'Rain' || main == 'Drizzle' || main == 'Thunderstorm';
    final foggy = main == 'Fog' || main == 'Mist' || main == 'Haze' || visibility < 2000;

    return WeatherCondition(
      description: desc,
      visibilityM: visibility,
      isNight: isNight,
      isRaining: rainy,
      isFoggy: foggy,
    );
  }
}

class WeatherService {
  static const String openWeatherApiKey = 'ad7c7f1285f568336c0fa3973983c0b9';


  Future<WeatherCondition?> fetchCurrent({required double lat, required double lon}) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?lat=$lat&lon=$lon&appid=$openWeatherApiKey&units=metric',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      return WeatherCondition.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null; // offline or API hiccup — app should degrade gracefully
    }
  }
}

// Calls the optional local LSTM prediction server (ml/lstm_server.py).
// If it's not running, this fails quietly and the app carries on without
// the prediction panel — the core alert flow never depends on this.

import 'dart:convert';
import 'package:http/http.dart' as http;

class SpeedPrediction {
  final double predictedSpeedKmph;
  final bool overLimit;

  SpeedPrediction({required this.predictedSpeedKmph, required this.overLimit});

  factory SpeedPrediction.fromJson(Map<String, dynamic> json) {
    return SpeedPrediction(
      predictedSpeedKmph: (json['predicted_speed_kmph'] ?? 0).toDouble(),
      overLimit: json['over_limit'] == true,
    );
  }
}

class PredictionService {
  /// Set this to your laptop's LAN IP while running lstm_server.py locally,
  /// e.g. 'http://192.168.0.106:5000'. Must be reachable from your phone —
  /// same WiFi network as your laptop.
  static const String SPEED_PREDICTION_URL = 'http://192.168.0.106:5000';

  Future<SpeedPrediction?> predictNext(List<double> recentSpeeds) async {
    final url = Uri.parse('$SPEED_PREDICTION_URL/predict');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'recent_speeds': recentSpeeds}),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return null;
      return SpeedPrediction.fromJson(jsonDecode(response.body));
    } catch (_) {
      return null; // server offline — that's fine, feature is optional
    }
  }
}

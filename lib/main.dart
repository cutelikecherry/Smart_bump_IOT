
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'firebase_options.dart'; 
import 'weather_service.dart';
import 'prediction_service.dart';
import 'risk_classifier.dart';
import 'behavior_classifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SmartBumpApp());
}

class SmartBumpApp extends StatelessWidget {
  const SmartBumpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart-Bump',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepOrange),
      home: const AlertScreen(),
    );
  }
}

class AlertHistoryEntry {
  final double distanceCm;
  final double speedKmph;
  final DateTime time;
  final RiskResult risk;
  final BehaviorProfile behavior;
  AlertHistoryEntry(this.distanceCm, this.speedKmph, this.time, this.risk, this.behavior);
}

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('alerts/latest');
  final FlutterTts _tts = FlutterTts();
  final WeatherService _weatherService = WeatherService();
  final PredictionService _predictionService = PredictionService();


  static const double DEMO_LAT = 12.9716; 
  static const double DEMO_LON = 77.5946;

  String _language = 'en-US';
  bool _voiceEnabled = true;
  bool _connected = false;
  bool _showAlert = false;
  double _lastDistance = 0;
  double _lastSpeed = 0;
  int _lastTimestampSeen = 0;
  final List<AlertHistoryEntry> _history = [];

  WeatherCondition? _weather;
  SpeedPrediction? _prediction;

  final Map<String, String> _languages = const {
    'en-US': 'English',
    'hi-IN': 'हिंदी (Hindi)',
    'kn-IN': 'ಕನ್ನಡ (Kannada)',
    'ta-IN': 'தமிழ் (Tamil)',
  };

  final Map<String, String> _slowDownPhrase = const {
    'en-US': 'Warning. Slow down. Speed breaker ahead.',
    'hi-IN': 'चेतावनी. धीमे चलें. आगे स्पीड ब्रेकर है.',
    'kn-IN': 'ಎಚ್ಚರಿಕೆ. ನಿಧಾನಿಸಿ. ಮುಂದೆ ಸ್ಪೀಡ್ ಬ್ರೇಕರ್ ಇದೆ.',
    'ta-IN': 'எச்சரிக்கை. மெதுவாக செல்லவும். முன்னால் ஸ்பீட் பிரேக்கர்.',
  };

  final Map<String, String> _hazardExtraPhrase = const {
    'en-US': 'Visibility is low. Drive extra carefully.',
    'hi-IN': 'दृश्यता कम है. अतिरिक्त सावधानी से चलें.',
    'kn-IN': 'ಗೋಚರತೆ ಕಡಿಮೆ ಇದೆ. ಹೆಚ್ಚು ಎಚ್ಚರಿಕೆಯಿಂದ ಚಾಲನೆ ಮಾಡಿ.',
    'ta-IN': 'பார்வை குறைவாக உள்ளது. மிகவும் கவனமாக ஓட்டவும்.',
  };

  @override
  void initState() {
    super.initState();
    _tts.setLanguage(_language);
    _listenForAlerts();
    _refreshWeather();
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(minutes: 10));
      if (!mounted) return false;
      await _refreshWeather();
      return true;
    });
  }

  Future<void> _refreshWeather() async {
    final w = await _weatherService.fetchCurrent(lat: DEMO_LAT, lon: DEMO_LON);
    if (mounted) setState(() => _weather = w);
  }

  void _listenForAlerts() {
    _dbRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data == null) return;
      final map = Map<String, dynamic>.from(data as Map);

      setState(() => _connected = true);

      final bool alertFlag = map['alert'] == true;
      final int timestamp = (map['timestamp'] ?? 0) is int
          ? map['timestamp']
          : int.tryParse('${map['timestamp']}') ?? 0;

      if (alertFlag && timestamp != _lastTimestampSeen) {
        _lastTimestampSeen = timestamp;
        final distance = (map['distance_cm'] ?? 0).toDouble();
        final speed = (map['speed_kmph'] ?? 0).toDouble();
        _triggerAlert(distance, speed);
      }
    }, onError: (_) {
      setState(() => _connected = false);
    });
  }

  RiskResult _lastRisk = RiskResult(RiskLevel.low, 1.0);

  Future<void> _triggerAlert(double distanceCm, double speedKmph) async {
    final risk = RiskClassifier.classify(
      speedKmph: speedKmph,
      weatherHazardous: _weather?.isHazardous ?? false,
      isNight: _weather?.isNight ?? false,
    );
    final behavior = BehaviorClassifier.classify(speedKmph);

    setState(() {
      _showAlert = true;
      _lastDistance = distanceCm;
      _lastSpeed = speedKmph;
      _lastRisk = risk;
      _history.insert(0, AlertHistoryEntry(distanceCm, speedKmph, DateTime.now(), risk, behavior));
      if (_history.length > 10) _history.removeLast();
    });

    
    _predictionService
        .predictNext(_history.map((h) => h.speedKmph).toList().reversed.toList())
        .then((p) {
      if (mounted) setState(() => _prediction = p);
    });

    if (_voiceEnabled) {
      _tts.setLanguage(_language);
      String phrase = _slowDownPhrase[_language] ?? _slowDownPhrase['en-US']!;
      if (_weather?.isHazardous == true) {
        phrase += ' ' + (_hazardExtraPhrase[_language] ?? _hazardExtraPhrase['en-US']!);
      }
      _tts.speak(phrase);
    }

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showAlert = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart-Bump'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Row(
                children: [
                  Icon(_connected ? Icons.cloud_done : Icons.cloud_off,
                      size: 18, color: _connected ? Colors.green : Colors.grey),
                  const SizedBox(width: 6),
                  Text(_connected ? 'Live' : 'Waiting...'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMainContent(),
          if (_showAlert) _buildAlertOverlay(),
        ],
      ),
    );
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.amber.shade800;
      case RiskLevel.high:
        return Colors.red;
    }
  }

  Widget _riskBadge(RiskResult risk, {bool light = false}) {
    final color = _riskColor(risk.level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: light ? Colors.white : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: light ? Colors.white : color, width: 1.5),
      ),
      child: Text(
        '${risk.label} risk',
        style: TextStyle(
          color: light ? color : color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildWeatherBanner() {
    if (_weather == null) {
      return const SizedBox.shrink();
    }
    final w = _weather!;
    if (!w.isHazardous) return const SizedBox.shrink();

    String reason = w.isRaining
        ? 'Rain'
        : w.isFoggy
            ? 'Low visibility / fog'
            : 'Night, reduced visibility';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_off, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$reason near the bump — alerts are boosted for extra caution.',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorSummary() {
    if (_history.isEmpty) return const SizedBox.shrink();

    final counts = {'Cautious': 0, 'Moderate': 0, 'Aggressive': 0};
    for (final h in _history) {
      counts[h.behavior.label] = (counts[h.behavior.label] ?? 0) + 1;
    }
    final colors = {
      'Cautious': Colors.green,
      'Moderate': Colors.amber.shade800,
      'Aggressive': Colors.red,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent behavior mix (last ${_history.length})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: counts.entries.map((e) {
                return Column(
                  children: [
                    Text('${e.value}',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: colors[e.key])),
                    Text(e.key, style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    if (_prediction == null) return const SizedBox.shrink();
    final p = _prediction!;
    return Card(
      color: p.overLimit ? Colors.red.shade50 : Colors.green.shade50,
      child: ListTile(
        leading: Icon(Icons.trending_up, color: p.overLimit ? Colors.red : Colors.green),
        title: Text('Predicted next speed: ${p.predictedSpeedKmph.toStringAsFixed(1)} km/h'),
        subtitle: Text(p.overLimit
            ? 'Trending above the safe limit — LSTM prediction'
            : 'Within the safe range — LSTM prediction'),
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWeatherBanner(),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _language,
                        decoration: const InputDecoration(labelText: 'Alert voice language'),
                        items: _languages.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setState(() => _language = v ?? 'en-US'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        const Text('Voice', style: TextStyle(fontSize: 12)),
                        Switch(value: _voiceEnabled, onChanged: (v) => setState(() => _voiceEnabled = v)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildBehaviorSummary(),
            const SizedBox(height: 12),
            _buildPredictionCard(),
            const SizedBox(height: 12),
            const Text('Recent alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: _history.isEmpty
                  ? const Center(child: Text('No alerts yet — waiting for a vehicle to cross the geofence.'))
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, i) {
                        final h = _history[i];
                        return ListTile(
                          leading: Icon(Icons.warning_amber, color: _riskColor(h.risk.level)),
                          title: Text('${h.speedKmph.toStringAsFixed(1)} km/h at ${h.distanceCm.toStringAsFixed(0)} cm'),
                          subtitle: Text(
                              '${h.time.hour.toString().padLeft(2, '0')}:${h.time.minute.toString().padLeft(2, '0')}:${h.time.second.toString().padLeft(2, '0')}  •  ${h.behavior.label}'),
                          trailing: _riskBadge(h.risk),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertOverlay() {
    final hazardous = _weather?.isHazardous == true;
    return Positioned.fill(
      child: Material(
        color: hazardous ? Colors.red.shade800 : Colors.deepOrange.shade700,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 96),
              const SizedBox(height: 16),
              const Text('SLOW DOWN',
                  style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(hazardous ? 'Speed breaker ahead — low visibility conditions' : 'Speed breaker ahead',
                  style: const TextStyle(color: Colors.white70, fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Text('Distance: ${_lastDistance.toStringAsFixed(0)} cm', style: const TextStyle(color: Colors.white, fontSize: 18)),
              Text('Speed: ${_lastSpeed.toStringAsFixed(1)} km/h', style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 12),
              _riskBadge(_lastRisk, light: true),
            ],
          ),
        ),
      ),
    );
  }
}
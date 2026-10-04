
import 'dart:math';

enum RiskLevel { low, medium, high }

class RiskResult {
  final RiskLevel level;
  final double confidence; 
  RiskResult(this.level, this.confidence);

  String get label {
    switch (level) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
    }
  }
}

class RiskClassifier {

  static const List<List<double>> _weights = [
    [-11.592483, -3.469989, -2.497239], // Low
    [-0.448705, -0.156912, -0.002119], // Medium
    [12.041188, 3.626901, 2.499357], // High
  ];
  static const List<double> _biases = [6.324448, 1.829858, -8.154306];

  static const double _speedNormFactor = 50.0; // matches training normalization

  static RiskResult classify({
    required double speedKmph,
    required bool weatherHazardous,
    required bool isNight,
  }) {
    final features = [
      speedKmph / _speedNormFactor,
      weatherHazardous ? 1.0 : 0.0,
      isNight ? 1.0 : 0.0,
    ];

    final scores = List<double>.generate(3, (classIndex) {
      double sum = _biases[classIndex];
      for (int f = 0; f < features.length; f++) {
        sum += _weights[classIndex][f] * features[f];
      }
      return sum;
    });

    final probs = _softmax(scores);
    int bestIndex = 0;
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > probs[bestIndex]) bestIndex = i;
    }

    final levels = [RiskLevel.low, RiskLevel.medium, RiskLevel.high];
    return RiskResult(levels[bestIndex], probs[bestIndex]);
  }

  static List<double> _softmax(List<double> scores) {
    final maxScore = scores.reduce(max);
    final exps = scores.map((s) => exp(s - maxScore)).toList();
    final sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
  }
}

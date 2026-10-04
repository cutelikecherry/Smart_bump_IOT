
class BehaviorProfile {
  final String label; 
  BehaviorProfile(this.label);
}

class BehaviorClassifier {
  static const List<String> _labels = ['Cautious', 'Moderate', 'Aggressive'];


  static const List<double> _centroids = [0.285593, 0.570869, 0.871272];

  static const double _speedNormFactor = 50.0;

  static BehaviorProfile classify(double speedKmph) {
    final normSpeed = speedKmph / _speedNormFactor;

    int closestIndex = 0;
    double closestDist = (normSpeed - _centroids[0]).abs();
    for (int i = 1; i < _centroids.length; i++) {
      final dist = (normSpeed - _centroids[i]).abs();
      if (dist < closestDist) {
        closestDist = dist;
        closestIndex = i;
      }
    }

    return BehaviorProfile(_labels[closestIndex]);
  }
}

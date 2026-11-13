/// How the distance of a manually logged (indoor) session is entered.
enum ManualDistanceMode { kilometers, laps }

/// Figures for a session that was typed in instead of tracked by GPS.
class ManualSessionStats {
  const ManualSessionStats({
    required this.distanceKm,
    required this.durationSeconds,
    required this.caloriesBurned,
    required this.averagePace,
    required this.steps,
  });

  final double distanceKm;
  final int durationSeconds;
  final int caloriesBurned;

  /// Minutes per kilometer, matching the live tracker's pace.
  final double averagePace;
  final int steps;

  /// Returns null when the input cannot describe a real session.
  static ManualSessionStats? calculate({
    required ManualDistanceMode mode,
    double? kilometers,
    double? laps,
    double? lapLengthMeters,
    required int durationSeconds,
    required int caloriesPerKm,
    bool countSteps = true,
  }) {
    if (durationSeconds <= 0) {
      return null;
    }

    final double distanceKm;
    switch (mode) {
      case ManualDistanceMode.kilometers:
        distanceKm = kilometers ?? 0;
      case ManualDistanceMode.laps:
        distanceKm = ((laps ?? 0) * (lapLengthMeters ?? 0)) / 1000;
    }

    if (distanceKm.isNaN || distanceKm.isInfinite || distanceKm <= 0) {
      return null;
    }

    return ManualSessionStats(
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      caloriesBurned: (distanceKm * caloriesPerKm).round(),
      averagePace: (durationSeconds / 60) / distanceKm,
      steps: countSteps ? (distanceKm * 1000 * 1.3).round() : 0,
    );
  }
}

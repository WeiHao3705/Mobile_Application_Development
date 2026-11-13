import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_application_development/utils/manual_session_calculator.dart';

void main() {
  test('kilometers mode computes calories, pace and steps', () {
    final stats = ManualSessionStats.calculate(
      mode: ManualDistanceMode.kilometers,
      kilometers: 5,
      durationSeconds: 30 * 60,
      caloriesPerKm: 60,
    )!;

    expect(stats.distanceKm, 5);
    expect(stats.caloriesBurned, 300);
    expect(stats.averagePace, closeTo(6, 0.001)); // 6 min/km
    expect(stats.steps, 6500);
  });

  test('laps mode converts laps x length to kilometers', () {
    final stats = ManualSessionStats.calculate(
      mode: ManualDistanceMode.laps,
      laps: 10,
      lapLengthMeters: 400,
      durationSeconds: 20 * 60,
      caloriesPerKm: 100,
    )!;

    expect(stats.distanceKm, 4);
    expect(stats.caloriesBurned, 400);
  });

  test('swimming can skip the step estimate', () {
    final stats = ManualSessionStats.calculate(
      mode: ManualDistanceMode.laps,
      laps: 20,
      lapLengthMeters: 25,
      durationSeconds: 15 * 60,
      caloriesPerKm: 400,
      countSteps: false,
    )!;

    expect(stats.distanceKm, 0.5);
    expect(stats.steps, 0);
  });

  test('invalid input returns null', () {
    ManualSessionStats? calc({
      ManualDistanceMode mode = ManualDistanceMode.kilometers,
      double? km,
      double? laps,
      double? length,
      int seconds = 600,
    }) {
      return ManualSessionStats.calculate(
        mode: mode,
        kilometers: km,
        laps: laps,
        lapLengthMeters: length,
        durationSeconds: seconds,
        caloriesPerKm: 50,
      );
    }

    expect(calc(km: 0), isNull);
    expect(calc(km: -2), isNull);
    expect(calc(km: null), isNull);
    expect(calc(km: 3, seconds: 0), isNull);
    expect(calc(mode: ManualDistanceMode.laps, laps: 5), isNull);
    expect(calc(mode: ManualDistanceMode.laps, length: 25), isNull);
    expect(calc(km: double.nan), isNull);
  });
}

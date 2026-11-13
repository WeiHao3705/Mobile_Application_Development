import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_application_development/controllers/tracking_controller.dart';

final DateTime _t0 = DateTime.utc(2026, 1, 1, 8);

// ~111 m per 0.001 degrees of latitude.
Position _fix({
  required double lat,
  required int seconds,
  double accuracy = 5,
  double altitude = 10,
}) {
  return Position(
    latitude: lat,
    longitude: 101.0,
    timestamp: _t0.add(Duration(seconds: seconds)),
    accuracy: accuracy,
    altitude: altitude,
    altitudeAccuracy: 3,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  late TrackingController controller;

  setUp(() => controller = TrackingController());
  tearDown(() => controller.dispose());

  test('first fix anchors the route without adding distance', () {
    controller.handlePositionForTesting(_fix(lat: 3.000, seconds: 0));
    expect(controller.totalDistance, 0);
    expect(controller.locationHistory, hasLength(1));
  });

  test('real movement adds distance', () {
    controller.handlePositionForTesting(_fix(lat: 3.000, seconds: 0));
    controller.handlePositionForTesting(_fix(lat: 3.001, seconds: 60));
    expect(controller.totalDistance, closeTo(0.111, 0.005));
  });

  test('inaccurate fixes are ignored and flag a weak signal', () {
    controller.handlePositionForTesting(_fix(lat: 3.000, seconds: 0));
    controller.handlePositionForTesting(
      _fix(lat: 3.001, seconds: 60, accuracy: 80),
    );
    expect(controller.totalDistance, 0);
    expect(controller.hasWeakSignal, isTrue);

    controller.handlePositionForTesting(_fix(lat: 3.001, seconds: 90));
    expect(controller.hasWeakSignal, isFalse);
    expect(controller.totalDistance, greaterThan(0.1));
  });

  test('GPS wobble while standing still adds nothing', () {
    controller.handlePositionForTesting(_fix(lat: 3.000000, seconds: 0));
    for (var i = 1; i <= 10; i++) {
      // About 1 m of jitter each way.
      controller.handlePositionForTesting(
        _fix(lat: i.isEven ? 3.000009 : 3.000000, seconds: i * 2),
      );
    }
    expect(controller.totalDistance, 0);
  });

  test('impossible speed jumps are rejected', () {
    controller.handlePositionForTesting(_fix(lat: 3.000, seconds: 0));
    // 1.1 km in 5 seconds is far beyond any walking, running or cycling speed.
    controller.handlePositionForTesting(_fix(lat: 3.010, seconds: 5));
    expect(controller.totalDistance, 0);
  });

  test('pausing re-anchors instead of counting the gap', () {
    controller.handlePositionForTesting(_fix(lat: 3.000, seconds: 0));
    controller.handlePositionForTesting(_fix(lat: 3.001, seconds: 60));
    final before = controller.totalDistance;

    controller.stopTracking();
    // Resume far away; the first fix must not add the distance travelled
    // while paused.
    controller.handlePositionForTesting(_fix(lat: 3.050, seconds: 600));
    expect(controller.totalDistance, before);
  });

  test('elevation gain ignores noise but counts real climbs', () {
    controller.handlePositionForTesting(
      _fix(lat: 3.000, seconds: 0, altitude: 10),
    );
    controller.handlePositionForTesting(
      _fix(lat: 3.001, seconds: 60, altitude: 11),
    );
    controller.handlePositionForTesting(
      _fix(lat: 3.002, seconds: 120, altitude: 10.5),
    );
    expect(controller.elevationGain, 0);

    controller.handlePositionForTesting(
      _fix(lat: 3.003, seconds: 180, altitude: 20),
    );
    expect(controller.elevationGain, 10);
  });

  test('altitude of exactly 0 (sea level) is handled', () {
    controller.handlePositionForTesting(
      _fix(lat: 3.000, seconds: 0, altitude: 0),
    );
    controller.handlePositionForTesting(
      _fix(lat: 3.001, seconds: 60, altitude: 8),
    );
    expect(controller.elevationGain, 8);
  });
}

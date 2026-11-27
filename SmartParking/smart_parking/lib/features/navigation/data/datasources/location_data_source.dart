import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/navigation_location_model.dart';

abstract class LocationDataSource {
  Future<NavigationLocationModel> getCurrentLocation();

  Stream<NavigationLocationModel> watchLocation();
}

class LocationDataSourceImpl implements LocationDataSource {
  const LocationDataSourceImpl();

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Vui lòng bật GPS trên thiết bị.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Quyền truy cập vị trí bị từ chối.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Vui lòng cấp quyền vị trí trong cài đặt ứng dụng.');
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw Exception('Không có quyền truy cập vị trí.');
    }
  }

  @override
  Future<NavigationLocationModel> getCurrentLocation() async {
    await _ensureLocationPermission();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return NavigationLocationModel.fromPosition(position);
  }

  @override
  Stream<NavigationLocationModel> watchLocation() async* {
    await _ensureLocationPermission();

    final LocationSettings settings =
        defaultTargetPlatform == TargetPlatform.android
            ? AndroidSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                distanceFilter: 0,
                intervalDuration: const Duration(seconds: 1),
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                distanceFilter: 0,
              );

    final stopwatch = Stopwatch()..start();
    int? previousUpdate;

    yield* Geolocator.getPositionStream(
      locationSettings: settings,
    ).map((position) {
      final now = stopwatch.elapsedMilliseconds;
      final interval = previousUpdate == null
          ? 'first'
          : '${now - previousUpdate!} ms';
      previousUpdate = now;

      if (kDebugMode) {
        final age = DateTime.now().difference(position.timestamp);
        debugPrint(
          'GPS UPDATE: interval=$interval, '
          'age=${age.inMilliseconds} ms, '
          'accuracy=${position.accuracy.toStringAsFixed(1)} m, '
          'speed=${position.speed.toStringAsFixed(1)} m/s',
        );
      }

      return NavigationLocationModel.fromPosition(position);
    });
  }
}

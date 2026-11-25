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

    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).map((position) => NavigationLocationModel.fromPosition(position));
  }
}

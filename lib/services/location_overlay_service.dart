import 'package:geolocator/geolocator.dart';
import 'package:gps_camera/models/camera_overlay_data.dart';

class LocationOverlayService {
  const LocationOverlayService();

  Future<CameraOverlayData> getOverlayData() async {
    await _ensureLocationAccess();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return _toOverlayData(position);
  }

  Stream<CameraOverlayData> watchOverlayData() async* {
    yield await getOverlayData();

    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).map(_toOverlayData);
  }

  Future<void> _ensureLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const PermissionDeniedException('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'Location permission is permanently denied.',
      );
    }
  }

  CameraOverlayData _toOverlayData(Position position) {
    return CameraOverlayData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      timestamp: position.timestamp,
    );
  }
}

import 'package:location/location.dart';

class NeoLocationUtil {
  final Location _location = Location();

  static LocationData? _cachedLocation;

  static LocationData? get cachedLocation => _cachedLocation;

  void cacheLocation(LocationData location) {
    _cachedLocation = location;
  }

  Future<LocationData?> getCurrentLocation() async {
    try {
      bool serviceEnabled = false;

      serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }

      if (!await hasLocationPermission()) {
        return null;
      }

      return _location.getLocation();
    } catch (e) {
      return null;
    }
  }

  Future<PermissionStatus?> checkAndRequestPermission() async {
    try {
      PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
      }
      return permissionStatus;
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasLocationPermission() async {
    try {
      final permissionStatus = await _location.hasPermission();
      return permissionStatus == PermissionStatus.granted || permissionStatus == PermissionStatus.grantedLimited;
    } catch (e) {
      return false;
    }
  }
}

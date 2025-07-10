import 'package:location/location.dart';

class NeoLocationUtil {
  final Location _location = Location();

  Future<LocationData?> getCurrentLocation() async {
    bool serviceEnabled = false;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    final isPermissionGranted = await checkAndRequestPermission() == PermissionStatus.granted;
    if (!isPermissionGranted) {
      return null;
    }

    return _location.getLocation();
  }

  Future<PermissionStatus?> checkAndRequestPermission() async {
    PermissionStatus permissionStatus = await _location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await _location.requestPermission();
    }
    return permissionStatus;
  }

  Future<bool> hasLocationPermission() async {
    final permissionStatus = await _location.hasPermission();
    return permissionStatus == PermissionStatus.granted || permissionStatus == PermissionStatus.grantedLimited;
  }
}

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:location/location.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';

class NeoLocationUtil {
  late final Location _location = Location();

  static LocationData? _cachedLocation;

  static LocationData? get cachedLocation => _cachedLocation;

  late final _neoLogger = GetIt.I.get<NeoLogger>();

  void cacheLocation(LocationData location) {
    _cachedLocation = location;
  }

  Future<LocationData?> getCurrentLocation() async {
    final bool isLocationSensorEnabled = await isLocationServiceEnabled();
    if (kIsWeb || !isLocationSensorEnabled) {
      return null;
    }
    try {
      if (!await hasLocationPermission()) {
        return null;
      }

      return _location.getLocation();
    } catch (e) {
      _neoLogger.logError("NeoLocationUtil-getCurrentLocation: $e");
      return null;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    if (kIsWeb) {
      return false;
    }
    try {
      return await _location.serviceEnabled();
    } catch (e) {
      _neoLogger.logError("NeoLocationUtil-isLocationServiceEnabled: $e");
      return false;
    }
  }

  Future<PermissionStatus?> checkAndRequestPermission() async {
    if (kIsWeb) {
      return null;
    }
    try {
      PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
      }
      return permissionStatus;
    } catch (e) {
      _neoLogger.logError("NeoLocationUtil-checkAndRequestPermission: $e");
      return null;
    }
  }

  Future<bool> hasLocationPermission() async {
    if (kIsWeb) {
      return false;
    }
    try {
      final permissionStatus = await _location.hasPermission();
      return permissionStatus == PermissionStatus.granted || permissionStatus == PermissionStatus.grantedLimited;
    } catch (e) {
      _neoLogger.logError("NeoLocationUtil-hasLocationPermission: $e");
      return false;
    }
  }
}

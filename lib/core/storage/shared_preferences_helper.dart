import 'package:burgan_core/burgan_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class _Constants {
  static const String sharedPrefKeyLanguage = "shared_pref_key_language";
  static const String sharedPrefKeyDeviceId = "shared_pref_key_device_id";
  static const String sharedPrefKeyDeviceInfo = "shared_pref_key_device_info";
  static const String sharedPrefKeyTokenId = "shared_pref_key_token_id";
  static const String sharedPrefKeyAuthToken = "shared_pref_key_auth_token";
}

class SharedPreferencesHelper {
  SharedPreferencesHelper._();

  static SharedPreferencesHelper shared = SharedPreferencesHelper._();
  static SharedPreferences? _preferences;

  static init() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _setInitialParameters();
  }

  static _setInitialParameters() async {
    final deviceUtil = DeviceUtil();
    final deviceId = await deviceUtil.getDeviceId();
    final deviceInfo = await deviceUtil.getDeviceInfo();
    if (!_preferences!.containsKey(_Constants.sharedPrefKeyDeviceId) && deviceId != null) {
      _setDeviceId(deviceId);
    }
    if (!_preferences!.containsKey(_Constants.sharedPrefKeyDeviceInfo) && deviceInfo != null) {
      _setDeviceInfo(deviceInfo);
    }
    if (!_preferences!.containsKey(_Constants.sharedPrefKeyTokenId)) {
      _setTokenId(const Uuid().v1());
    }
  }

  Future<bool> setLanguageCode(String languageCode) async {
    return await _preferences!.setString(_Constants.sharedPrefKeyLanguage, languageCode);
  }

  String? getLanguageCode() {
    return _preferences!.getString(_Constants.sharedPrefKeyLanguage);
  }

  static _setDeviceId(String deviceId) async {
    await _preferences!.setString(_Constants.sharedPrefKeyDeviceId, deviceId);
  }

  String? getDeviceId() {
    return _preferences!.getString(_Constants.sharedPrefKeyDeviceId);
  }

  static _setDeviceInfo(String deviceInfo) async {
    await _preferences!.setString(_Constants.sharedPrefKeyDeviceInfo, deviceInfo);
  }

  String? getDeviceInfo() {
    return _preferences!.getString(_Constants.sharedPrefKeyDeviceInfo);
  }

  static _setTokenId(String tokenId) async {
    await _preferences!.setString(_Constants.sharedPrefKeyTokenId, tokenId);
  }

  String? getTokenId() {
    return _preferences!.getString(_Constants.sharedPrefKeyTokenId);
  }

  Future<bool> setAuthToken(String? token) async {
    if (token == null) {
      if (_preferences!.containsKey(_Constants.sharedPrefKeyAuthToken)) {
        return await _preferences!.remove(_Constants.sharedPrefKeyAuthToken);
      }
      return true;
    } else {
      return await _preferences!.setString(_Constants.sharedPrefKeyAuthToken, token);
    }
  }

  String? getAuthToken() {
    return _preferences!.getString(_Constants.sharedPrefKeyAuthToken);
  }
}

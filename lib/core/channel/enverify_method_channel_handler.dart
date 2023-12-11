part of env_bridge;

class _EnverifyMethodChannelHandler {
  static const platformMethods = MethodChannel("com.amorpihe.core/common/methods");

  Future<bool> startSDK(Map<String, String> requestedData) async {
    bool result = false;

    try {
      final response = await platformMethods.invokeMethod<bool>(_MethodNames.start.name, requestedData);
      result = response != null && response;
    } on PlatformException catch (e) {
      print("MethodChannel: exception: $e");
      result = false;
    }
    return result;
  }
}

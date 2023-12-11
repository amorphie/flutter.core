part of env_bridge;

class _MethodChannelHandler {
  static const platformMethods = MethodChannel("com.amorphie.core/common/methods");

  Future<bool> prepareEnverifySDK(Map<String, String> requestedData) async {
    bool result = false;

    try {
      final response = await platformMethods.invokeMethod<bool>(_MethodNames.prepareEnverifySDK.name, requestedData);
      result = response != null && response;
    } on PlatformException catch (e) {
      print("MethodChannel: exception: $e");
      result = false;
    }
    return result;
  }
}

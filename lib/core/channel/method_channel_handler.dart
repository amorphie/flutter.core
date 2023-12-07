import 'package:flutter/services.dart';

class MethhodChannelHandler {
  static const platformMethods = MethodChannel("com.amorpihe.core/enverify/methods");

  Future<bool> startSDK(Map<String, String> requestedData) async {
    bool result = false;

    try {
      final response = await platformMethods.invokeMethod<bool>(MethodName.start.name, requestedData);
      result = response != null && response;
    } on PlatformException catch (e) {
      print("MethodChannel: exception: $e");
      result = false;
    }
    return result;
  }
}

enum MethodName { start, stop }

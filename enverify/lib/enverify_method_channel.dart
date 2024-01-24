import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'enverify_platform_interface.dart';

/// An implementation of [EnverifyPlatform] that uses method channels.
class MethodChannelEnverify extends EnverifyPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('enverify');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

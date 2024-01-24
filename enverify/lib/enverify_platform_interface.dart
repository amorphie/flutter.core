import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'enverify_method_channel.dart';

abstract class EnverifyPlatform extends PlatformInterface {
  /// Constructs a EnverifyPlatform.
  EnverifyPlatform() : super(token: _token);

  static final Object _token = Object();

  static EnverifyPlatform _instance = MethodChannelEnverify();

  /// The default instance of [EnverifyPlatform] to use.
  ///
  /// Defaults to [MethodChannelEnverify].
  static EnverifyPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EnverifyPlatform] when
  /// they register themselves.
  static set instance(EnverifyPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

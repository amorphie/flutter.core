
import 'enverify_platform_interface.dart';

class Enverify {
  Future<String?> getPlatformVersion() {
    return EnverifyPlatform.instance.getPlatformVersion();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:enverify/enverify.dart';
import 'package:enverify/enverify_platform_interface.dart';
import 'package:enverify/enverify_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEnverifyPlatform
    with MockPlatformInterfaceMixin
    implements EnverifyPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final EnverifyPlatform initialPlatform = EnverifyPlatform.instance;

  test('$MethodChannelEnverify is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEnverify>());
  });

  test('getPlatformVersion', () async {
    Enverify enverifyPlugin = Enverify();
    MockEnverifyPlatform fakePlatform = MockEnverifyPlatform();
    EnverifyPlatform.instance = fakePlatform;

    expect(await enverifyPlugin.getPlatformVersion(), '42');
  });
}

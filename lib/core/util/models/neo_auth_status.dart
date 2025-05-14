import 'package:collection/collection.dart';

enum NeoAuthStatus {
  notLoggedIn(key: "NL"),
  oneFactorAuth(key: "1FA"),
  twoFactorAuth(key: "2FA");

  final String key;

  const NeoAuthStatus({required this.key});

  static NeoAuthStatus fromKey(String key) {
    return NeoAuthStatus.values.firstWhereOrNull((e) => e.key == key) ?? NeoAuthStatus.notLoggedIn;
  }
}

extension NeoAuthStatusExtension on NeoAuthStatus {
  bool get isTwoFactorAuth => this == NeoAuthStatus.twoFactorAuth;
}

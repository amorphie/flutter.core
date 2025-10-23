import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

// ignore: do_not_use_environment
const _currentEnvironment = String.fromEnvironment('environment');

abstract class _Constants {
  static const burganCallCenterHosts = [
    "test-ccesube.burgan.com.tr",
    "preprod-ccesube.burgan.com.tr",
    "dmzprod-ccesube.burgan.com.tr",
  ];
  static const onCallCenterHosts = [
    "test-ccesube.on.com.tr",
    "preprod-ccesube.on.com.tr",
    "dmzprod-ccesube.on.com.tr",
  ];
}

enum NeoEnvironmentType {
  dev,
  prep,
  prod,
  onDev,
  onPrep,
  onProd,
  ibDev,
  ibPrep,
  ibProd,
  ;

  static NeoEnvironmentType fromEnvironmentFile() {
    return NeoEnvironmentType.values.firstWhereOrNull((element) => element.value == _currentEnvironment) ??
        NeoEnvironmentType.dev;
  }
}

extension NeoEnvironmentTypeExtension on NeoEnvironmentType {
  String get value {
    return switch (this) {
      NeoEnvironmentType.dev => "dev",
      NeoEnvironmentType.prep => "prep",
      NeoEnvironmentType.prod => "prod",
      NeoEnvironmentType.onDev => "onDev",
      NeoEnvironmentType.onPrep => "onPrep",
      NeoEnvironmentType.onProd => "onProd",
      NeoEnvironmentType.ibDev => "ibDev",
      NeoEnvironmentType.ibPrep => "ibPrep",
      NeoEnvironmentType.ibProd => "ibProd",
    };
  }

  bool get isOn {
    return switch (this) {
      NeoEnvironmentType.onDev => true,
      NeoEnvironmentType.onPrep => true,
      NeoEnvironmentType.onProd => true,
      _ => false,
    };
  }

  bool get isBurgan {
    return switch (this) {
      NeoEnvironmentType.dev => true,
      NeoEnvironmentType.prep => true,
      NeoEnvironmentType.prod => true,
      _ => false,
    };
  }

  bool get isIb {
    return switch (this) {
      NeoEnvironmentType.ibDev => true,
      NeoEnvironmentType.ibPrep => true,
      NeoEnvironmentType.ibProd => true,
      _ => false,
    };
  }

  bool get isBurganCallCenter {
    return kIsWeb && _Constants.burganCallCenterHosts.any((host) => host == Uri.base.host);
  }

  bool get isOnCallCenter {
    return kIsWeb && _Constants.onCallCenterHosts.any((host) => host == Uri.base.host);
  }

  bool get isCallCenter {
    return isBurganCallCenter || isOnCallCenter;
  }

  bool get isDev {
    return switch (this) {
      NeoEnvironmentType.dev => true,
      NeoEnvironmentType.onDev => true,
      NeoEnvironmentType.ibDev => true,
      _ => false,
    };
  }

  bool get isPrep {
    return switch (this) {
      NeoEnvironmentType.prep => true,
      NeoEnvironmentType.onPrep => true,
      NeoEnvironmentType.ibPrep => true,
      _ => false,
    };
  }

  bool get isProd {
    return switch (this) {
      NeoEnvironmentType.prod => true,
      NeoEnvironmentType.onProd => true,
      NeoEnvironmentType.ibProd => true,
      _ => false,
    };
  }
}

import 'package:dengage_flutter/dengage_flutter.dart';

class NeoDengage {
  NeoDengage();

  //TODO: MAKE THİS FUNCTION CALL
  void setContactKey(String? key) {
    DengageFlutter.setContactKey(key);
  }

  //TODO: MAKE THİS FUNCTION CALL
  void setUserPermission({required bool granted}) {
    DengageFlutter.setUserPermission(granted);
  }
}

import 'package:neo_core/core/environment_variables/neo_environment_type.dart';

class NeoEnvironment {
  NeoEnvironment._();

  static late NeoEnvironmentType current;

  static void init() {
    current = NeoEnvironmentType.fromEnvironmentFile();
  }
}

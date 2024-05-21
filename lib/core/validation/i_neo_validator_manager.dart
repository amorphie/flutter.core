import 'package:neo_core/core/validation/neo_validator_result.dart';

abstract class INeoValidatorManager {
  Map<String, dynamic> validators;
  INeoValidatorManager({
    required this.validators,
  });
  List<NeoValidatorResult> validator(String? value);
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:neo_core/core/validation/fields/neo_field_between_validation.dart';
import 'package:neo_core/core/validation/fields/neo_field_length_validation.dart';
import 'package:neo_core/core/validation/fields/neo_field_max_validation.dart';
import 'package:neo_core/core/validation/fields/neo_field_min_validation.dart';
import 'package:neo_core/core/validation/fields/neo_field_regex_validation.dart';
import 'package:neo_core/core/validation/fields/neo_field_required_validation.dart';
import 'package:neo_core/core/validation/i_neo_field_validation.dart';
import 'package:neo_core/core/validation/i_neo_validator_manager.dart';
import 'package:neo_core/core/validation/neo_validator_result.dart';

class NeoValidatorManager implements INeoValidatorManager {
  @override
  Map<String, dynamic> validators;
  NeoValidatorManager({
    required this.validators,
  });

  @override
  List<NeoValidatorResult> validator(String? value) {
    final List<NeoValidatorResult> output = [];
    _validators.forEach((key, fieldValidator) {
      final String? message = fieldValidator.validate(value);
      if (message != null) {
        output.add(NeoValidatorResult(message));
      }
    });

    return output;
  }

  Map<String, INeoFieldValidation> get _validators {
    final Map<String, INeoFieldValidation> items = {};
    validators.forEach((key, value) {
      switch (key) {
        case "required":
          items.addAll({key: NeoFieldReuqiredValidation.fromJson(value)});
          break;
        case "length":
          items.addAll({key: NeoFieldLengthValidation.fromJson(value)});
          break;
        case "between":
          items.addAll({key: NeoFieldBetweenValidation.fromJson(value)});
          break;
        case "regex":
          items.addAll({key: NeoFieldRegexValidation.fromJson(value)});
          break;
        case "min":
          items.addAll({key: NeoFieldMinValidation.fromJson(value)});
          break;
        case "max":
          items.addAll({key: NeoFieldMaxValidation.fromJson(value)});
          break;
      }
    });
    return items;
  }
}

void main() {
  final stringValidators = {
    "required": {"message": "The field is required"},
    "length": {"length": 4, "message": "This field must be {length} characters long."},
  };
  final stringManager = NeoValidatorManager(validators: stringValidators);
  final stringResult = stringManager.validator("");
  debugPrint("stringResult: \n${stringResult.map((e) => e.message).join("\n")}");

  final intResult = NeoValidatorManager(
    validators: {
      "required": {"message": "The field is required"},
      "min": {"min": 4, "message": "This field must be greater than {min}"},
      "max": {"max": 8, "message": "This field must be less than {max}"},
    },
  ).validator("asd");
  debugPrint("intResult: \n${intResult.map((e) => e.message).join("\n")}");
}

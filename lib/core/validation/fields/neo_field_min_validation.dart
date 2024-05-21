import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/validation/i_neo_field_validation.dart';

part 'neo_field_min_validation.g.dart';

@JsonSerializable(createFieldMap: true, createPerFieldToJson: false)
class NeoFieldMinValidation extends INeoFieldValidation {
  int? min;

  @override
  String? message;

  NeoFieldMinValidation({
    this.min,
    this.message,
  });

  @override
  String? validate(String? value) {
    if (min == null) {
      throw Exception("Min value is required. Fill in the 'min' field to use validation");
    }
    try {
      final int? valueInt = int.tryParse(value!);
      if (valueInt != null && valueInt <= min!) {
        return null;
      }

      return validateMessage();
    } catch (e) {
      throw Exception("This validation only works with integer values");
    }
  }

  factory NeoFieldMinValidation.fromJson(Map<String, dynamic> json) => _$NeoFieldMinValidationFromJson(json);
  @override
  Map<String, String> get fieldMap => _$NeoFieldMinValidationFieldMap;
  @override
  String get defaultMessage => "This field must be greater than {min}";

  @override
  Map<String, dynamic> toJson() => _$NeoFieldMinValidationToJson(this);
}

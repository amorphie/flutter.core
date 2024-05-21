import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/validation/i_neo_field_validation.dart';

part 'neo_field_max_validation.g.dart';

@JsonSerializable(createFieldMap: true, createPerFieldToJson: false)
class NeoFieldMaxValidation extends INeoFieldValidation {
  int? max;

  @override
  String? message;

  NeoFieldMaxValidation({
    this.max,
    this.message,
  });

  @override
  String? validate(String? value) {
    if (max == null) {
      throw Exception("Max value is required. Fill in the 'max' field to use validation");
    }
    try {
      final int? valueInt = int.tryParse(value!);
      if (valueInt != null && valueInt <= max!) {
        return null;
      }
      return validateMessage();
    } catch (e) {
      throw Exception("This validation only works with integer values");
    }
  }

  factory NeoFieldMaxValidation.fromJson(Map<String, dynamic> json) => _$NeoFieldMaxValidationFromJson(json);
  @override
  Map<String, String> get fieldMap => _$NeoFieldMaxValidationFieldMap;
  @override
  String get defaultMessage => "This field must be greater than {max}";

  @override
  Map<String, dynamic> toJson() => _$NeoFieldMaxValidationToJson(this);
}

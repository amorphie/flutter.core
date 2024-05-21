import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/validation/i_neo_field_validation.dart';

part 'neo_field_between_validation.g.dart';

@JsonSerializable(createFieldMap: true, createPerFieldToJson: false)
class NeoFieldBetweenValidation extends INeoFieldValidation {
  int? start;
  int? end;

  @override
  String? message;

  NeoFieldBetweenValidation({
    this.start,
    this.end,
    this.message,
  });

  @override
  String? validate(String? value) {
    if (start == null || end == null) {
      throw Exception("Start and End values are required. Fill in the 'start' and 'end' fields to use validation");
    }
    try {
      final int? valueInt = int.tryParse(value!);
      if (valueInt != null && valueInt >= start! && valueInt <= end!) {
        return null;
      }
      return validateMessage();
    } catch (e) {
      throw Exception("This validation only works with integer values");
    }
  }

  factory NeoFieldBetweenValidation.fromJson(Map<String, dynamic> json) => _$NeoFieldBetweenValidationFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$NeoFieldBetweenValidationToJson(this);
  @override
  Map<String, String> get fieldMap => _$NeoFieldBetweenValidationFieldMap;
  @override
  String get defaultMessage => "This field must be between {start} and {end}";
}

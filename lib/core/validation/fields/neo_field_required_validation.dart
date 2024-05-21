import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/validation/i_neo_field_validation.dart';

part 'neo_field_required_validation.g.dart';

@JsonSerializable(createFieldMap: true, createPerFieldToJson: false)
class NeoFieldReuqiredValidation extends INeoFieldValidation {
  NeoFieldReuqiredValidation({this.message});

  @override
  String? message;

  @override
  String? validate(String? value) {
    if (value != null && value.isNotEmpty) {
      return null;
    }

    return validateMessage();
  }

  factory NeoFieldReuqiredValidation.fromJson(Map<String, dynamic> json) => _$NeoFieldReuqiredValidationFromJson(json);
  @override
  Map<String, String> get fieldMap => _$NeoFieldReuqiredValidationFieldMap;
  @override
  String get defaultMessage => "The field is required";

  @override
  Map<String, dynamic> toJson() => _$NeoFieldReuqiredValidationToJson(this);
}

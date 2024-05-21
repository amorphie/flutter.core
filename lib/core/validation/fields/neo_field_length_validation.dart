import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/validation/i_neo_field_validation.dart';

part 'neo_field_length_validation.g.dart';

@JsonSerializable(createFieldMap: true, createPerFieldToJson: false)
class NeoFieldLengthValidation extends INeoFieldValidation {
  int? length;

  @override
  String? message;
  NeoFieldLengthValidation({
    required this.length,
    this.message,
  });

  @override
  String? validate(String? value) {
    if (length == null) {
      throw Exception("Length value is required. Fill in the 'length' field to use validation");
    }
    if (value != null && value.length > length!) {
      return null;
    }
    return validateMessage();
  }

  factory NeoFieldLengthValidation.fromJson(Map<String, dynamic> json) => _$NeoFieldLengthValidationFromJson(json);

  @override
  Map<String, String> get fieldMap => _$NeoFieldLengthValidationFieldMap;
  @override
  String get defaultMessage => "This field must be {length} characters long.";

  @override
  Map<String, dynamic> toJson() => _$NeoFieldLengthValidationToJson(this);
}

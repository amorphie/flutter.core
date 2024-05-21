import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/validation/i_neo_field_validation.dart';

part 'neo_field_regex_validation.g.dart';

@JsonSerializable(createFieldMap: true, createPerFieldToJson: false)
class NeoFieldRegexValidation extends INeoFieldValidation {
  String? regex;

  @override
  String? message;
  NeoFieldRegexValidation({
    required this.regex,
    this.message,
  });

  @override
  String? validate(String? value) {
    if (regex == null) {
      throw Exception("Regex value is required. Fill in the 'regex' field to use validation");
    }
    if (value != null && RegExp(regex!).hasMatch(value)) {
      return null;
    }
    return validateMessage();
  }

  factory NeoFieldRegexValidation.fromJson(Map<String, dynamic> json) => _$NeoFieldRegexValidationFromJson(json);

  @override
  Map<String, String> get fieldMap => _$NeoFieldRegexValidationFieldMap;
  @override
  String get defaultMessage => "This field does not match.";

  @override
  Map<String, dynamic> toJson() => _$NeoFieldRegexValidationToJson(this);
}

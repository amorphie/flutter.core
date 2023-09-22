import 'package:flutter/material.dart';

extension FormFieldValidatorExtension on FormFieldValidator<String> {
  FormFieldValidator<String> mergeWith(FormFieldValidator<String> otherValidator) {
    return (input) => this(input) ?? otherValidator(input);
  }
}

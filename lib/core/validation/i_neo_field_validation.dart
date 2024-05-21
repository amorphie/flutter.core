abstract class INeoFieldValidation {
  String? get message;

  INeoFieldValidation();

  String? validate(String? value);

  Map<String, dynamic> toJson();

  Map<String, String> get fieldMap;

  String get defaultMessage;

  String validateMessage() {
    String msg = message ?? defaultMessage;

    final data = toJson();

    fieldMap.forEach((key, value) {
      if (data[key] != null) {
        msg = msg.replaceAll("{$key}", data[key].toString());
      }
    });

    return msg;
  }
}

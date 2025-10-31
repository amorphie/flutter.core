import 'package:flutter/material.dart';

enum Language {
  turkish("tr"),
  english("en");

  final String languageCode;

  const Language(this.languageCode);

  factory Language.fromString(String languageCode) {
    return values.firstWhere(
      (e) => e.languageCode == languageCode,
      orElse: () => defaultLanguage,
    );
  }

  static Language get defaultLanguage => Language.turkish;

  String get languageName {
    switch (this) {
      case Language.turkish:
        //STOPSHIP: add Localization
        return "Türkçe";
      case Language.english:
        //STOPSHIP: add Localization
        return "English";
    }
  }

  Locale get locale => Locale(languageCode);

  /// Accept-Language header formatında dil kodu döndürür
  /// Örnek: "tr-TR", "en-US"
  String get toAcceptLanguage {
    switch (this) {
      case Language.turkish:
        return "tr-TR";
      case Language.english:
        return "en-US";
    }
  }
}

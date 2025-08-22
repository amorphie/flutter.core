/*
 * neo_bank
 *
 * Created on 4/10/2023.
 * Copyright (c) 2023 BurganBank. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of BurganBank.
 * Any reproduction of this material must contain this notice.
 */

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
}

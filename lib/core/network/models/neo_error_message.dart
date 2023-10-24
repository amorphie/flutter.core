/*
 * burgan_core
 *
 * Created on 24/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'neo_error_message.g.dart';

abstract class _Constants {
  static const languageCodeTurkish = "tr";
  static const languageCodeEnglish = "en";
  static const defaultTitleTurkish = "Sistemlerimizde bir hata olustu.";
  static const defaultSubtitleTurkish = "Hatayi incelemeye aldik, daha sonra tekrar dener misiniz.";
  static const defaultTitleEnglish = "An error has occurred in our systems.";
  static const defaultSubtitleEnglish = "We have investigated the error, could you please try again later.";
}

@JsonSerializable(createToJson: false)
class NeoErrorMessage extends Equatable {
  @JsonKey(name: "language", defaultValue: _Constants.languageCodeEnglish)
  final String language;

  @JsonKey(name: "title", defaultValue: "")
  final String title;

  @JsonKey(name: "subtitle", defaultValue: "")
  final String subtitle;

  @JsonKey(name: "icon")
  final String? iconPath;

  @override
  List<Object?> get props => [language, title, subtitle, iconPath];

  const NeoErrorMessage({required this.language, required this.title, required this.subtitle, this.iconPath});

  factory NeoErrorMessage.fromJson(Map<String, dynamic> json) => _$NeoErrorMessageFromJson(json);

  factory NeoErrorMessage.defaultErrorTR() => const NeoErrorMessage(
        language: _Constants.languageCodeTurkish,
        title: _Constants.defaultTitleTurkish,
        subtitle: _Constants.defaultSubtitleTurkish,
      );

  static const defaultErrorTurkish = NeoErrorMessage(
    language: _Constants.languageCodeTurkish,
    title: _Constants.defaultTitleTurkish,
    subtitle: _Constants.defaultSubtitleTurkish,
  );

  static const defaultErrorEnglish = NeoErrorMessage(
    language: _Constants.languageCodeEnglish,
    title: _Constants.defaultTitleEnglish,
    subtitle: _Constants.defaultSubtitleEnglish,
  );
}

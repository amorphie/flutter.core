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

part of 'localization_bloc.dart';

abstract class LocalizationEvent extends Equatable {
  const LocalizationEvent();
}

class LocalizationEventChangeLanguage extends LocalizationEvent {
  final Language language;

  const LocalizationEventChangeLanguage(this.language);

  @override
  List<Object?> get props => [language];
}

class LocalizationEventSwitchLanguage extends LocalizationEvent {
  @override
  List<Object?> get props => [];
}

class LocalizationEventFetchLocalizationFromAPI extends LocalizationEvent {
  @override
  List<Object?> get props => [];
}

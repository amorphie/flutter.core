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

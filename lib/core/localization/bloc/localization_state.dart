part of 'localization_bloc.dart';

class LocalizationState extends Equatable {
  const LocalizationState(this.language, {this.lastUpdatedTime});

  final Language language;
  final DateTime? lastUpdatedTime;

  @override
  List<Object?> get props => [language, lastUpdatedTime];

  LocalizationState copyWith({
    Language? language,
    DateTime? lastUpdatedTime,
  }) {
    return LocalizationState(
      language ?? this.language,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
    );
  }
}

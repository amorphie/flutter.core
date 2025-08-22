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

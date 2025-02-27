/*
 * neo_core
 *
 * Created on 21/3/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

part of 'neo_page_bloc.dart';

sealed class NeoPageEvent extends Equatable {
  const NeoPageEvent();
}

class NeoPageEventResetForm extends NeoPageEvent {
  const NeoPageEventResetForm();

  @override
  List<Object?> get props => [];
}

class NeoPageEventAddInitialParameters extends NeoPageEvent {
  final Map<String, dynamic> parameters;

  const NeoPageEventAddInitialParameters(this.parameters);

  @override
  List<Object?> get props => [parameters];
}

class NeoPageEventAddAllParameters extends NeoPageEvent {
  final Map<String, dynamic> parameters;

  const NeoPageEventAddAllParameters(this.parameters);

  @override
  List<Object?> get props => [parameters];
}

class NeoPageEventAddParametersIntoArray extends NeoPageEvent {
  final dynamic itemIdentifierKey;
  final String sharedDataKey;
  final Map value;
  final bool isInitialValue;

  const NeoPageEventAddParametersIntoArray({
    required this.itemIdentifierKey,
    required this.sharedDataKey,
    required this.value,
    this.isInitialValue = false,
  });

  @override
  List<Object?> get props => [itemIdentifierKey, sharedDataKey, value, isInitialValue];
}

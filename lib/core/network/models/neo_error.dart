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

import 'package:burgan_core/core/network/models/neo_error_display_method.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'neo_error.g.dart';

abstract class _Constants {
  static const defaultErrorCode = 400;
  static const defaultErrorMessage = "Error!"; // STOPSHIP: Update default error model
  static const defaultErrorDisplayMode = NeoErrorDisplayMethod.popup;
}

@JsonSerializable(createToJson: false)
class NeoError extends Equatable {
  @JsonKey(name: "response-code", defaultValue: _Constants.defaultErrorCode)
  final int responseCode;

  @JsonKey(name: "display-mode")
  final NeoErrorDisplayMethod displayMode;

  @JsonKey(name: "messages")
  // STOPSHIP: Update message data model
  final String? message;

  @override
  List<Object?> get props => [responseCode, displayMode, message];

  @override
  String toString() => message ?? "";

  const NeoError({required this.responseCode, this.displayMode = _Constants.defaultErrorDisplayMode, this.message});

  factory NeoError.fromJson(Map<String, dynamic> json) => _$NeoErrorFromJson(json);

  factory NeoError.defaultError() => const NeoError(
        responseCode: _Constants.defaultErrorCode,
        displayMode: _Constants.defaultErrorDisplayMode,
        message: _Constants.defaultErrorMessage,
      );
}

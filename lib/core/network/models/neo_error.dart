/*
 * neo_core
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
import 'package:neo_core/core/network/models/neo_error_display_method.dart';

part 'neo_error.g.dart';

abstract class _Constants {
  static const defaultErrorCode = "400";
  static const defaultErrorDisplayMode = NeoErrorDisplayMethod.popup;
  static const defaultErrorTitle = "general_noResponse_title";
  static const defaultErrorMessage = "general_noResponse_text";
}

@JsonSerializable()
class NeoError extends Equatable {
  @JsonKey(name: "response-code")
  final String responseCode;

  @JsonKey(name: "display-mode")
  final NeoErrorDisplayMethod displayMode;

  @JsonKey(name: "title")
  final String title;

  @JsonKey(name: "message")
  final String message;

  @override
  List<Object?> get props => [responseCode, displayMode, title];

  const NeoError({
    this.responseCode = _Constants.defaultErrorCode,
    this.displayMode = _Constants.defaultErrorDisplayMode,
    this.title = _Constants.defaultErrorTitle,
    this.message = _Constants.defaultErrorMessage,
  });

  Map<String, dynamic> toJson() => _$NeoErrorToJson(this);

  factory NeoError.fromJson(Map<String, dynamic> json) => _$NeoErrorFromJson(json);

  factory NeoError.defaultError() => const NeoError();
}

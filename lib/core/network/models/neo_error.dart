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
  static const defaultErrorCode = 400;
  static const defaultErrorDisplayMode = NeoErrorDisplayMethod.popup;
  static const defaultErrorTitle = "general_noResponse_title";
  static const defaultErrorMessage = "general_noResponse_text";
  static const defaultErrorIcon = "error";
  static const defaultErrorCloseButtonText = "general_okay_button";
}

@JsonSerializable()
class NeoError extends Equatable {
  @JsonKey(name: "errorCode")
  final int errorCode;

  @JsonKey(name: "errorType")
  final NeoErrorDisplayMethod errorType;

  @JsonKey(name: "error")
  final NeoErrorDetail error;

  @override
  List<Object?> get props => [errorCode, errorType, error];

  const NeoError({
    this.errorCode = _Constants.defaultErrorCode,
    this.errorType = _Constants.defaultErrorDisplayMode,
    this.error = const NeoErrorDetail(),
  });

  Map<String, dynamic> toJson() => _$NeoErrorToJson(this);

  factory NeoError.fromJson(Map<String, dynamic> json) => _$NeoErrorFromJson(json);

  factory NeoError.defaultError() => const NeoError();
}

@JsonSerializable()
class NeoErrorDetail extends Equatable {
  @JsonKey(name: "icon")
  final String icon;

  @JsonKey(name: "title")
  final String title;

  @JsonKey(name: "description")
  final String description;

  @JsonKey(name: "closeButton")
  final String closeButton;

  @override
  List<Object?> get props => [icon, title, description, closeButton];

  const NeoErrorDetail({
    this.icon = _Constants.defaultErrorIcon,
    this.title = _Constants.defaultErrorTitle,
    this.description = _Constants.defaultErrorMessage,
    this.closeButton = _Constants.defaultErrorCloseButtonText,
  });

  Map<String, dynamic> toJson() => _$NeoErrorDetailToJson(this);

  factory NeoErrorDetail.fromJson(Map<String, dynamic> json) => _$NeoErrorDetailFromJson(json);
}

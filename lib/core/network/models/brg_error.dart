/*
 * burgan_core
 *
 * Created on 22/9/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'brg_error.g.dart';

// STOPSHIP: Rename as NeoError and update error model
@JsonSerializable(createToJson: false)
class BrgError extends Equatable {
  @JsonKey(ignore: true)
  final int? httpStatusCode;

  @JsonKey(required: true)
  final String? errorCode;

  @JsonKey(required: true)
  final String? message;

  @override
  List<Object?> get props => [errorCode, message];

  @override
  String toString() => message ?? "";

  const BrgError({this.httpStatusCode, this.errorCode, this.message});

  BrgError copyWith({
    int? httpStatusCode,
    String? errorCode,
    String? message,
  }) {
    return BrgError(
      httpStatusCode: httpStatusCode ?? this.httpStatusCode,
      errorCode: errorCode ?? this.errorCode,
      message: message ?? this.message,
    );
  }

  factory BrgError.fromJson(Map<String, dynamic> json) => _$BrgErrorFromJson(json);

  // STOPSHIP: Update default error model with localized text
  factory BrgError.defaultError() => const BrgError(
        message: "Teknik bir hata meydana geldi!",
      );
}

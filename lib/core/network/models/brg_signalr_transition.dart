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

part 'brg_signalr_transition.g.dart';

@JsonSerializable(createToJson: false)
class BrgSignalRTransition extends Equatable {
  @JsonKey(name: "transition")
  final String transitionId;

  @JsonKey(name: "page", defaultValue: {})
  final Map<String, dynamic> pageDetails;

  @JsonKey(name: "additionalData", defaultValue: null)
  final Map<String, dynamic>? additionalData;

  @JsonKey(name: "message", defaultValue: "")
  final String errorMessage;

  const BrgSignalRTransition({
    required this.transitionId,
    required this.pageDetails,
    required this.errorMessage,
    this.additionalData,
  });

  @override
  List<Object?> get props => [transitionId, pageDetails, errorMessage];

  factory BrgSignalRTransition.fromJson(Map<String, dynamic> json) => _$BrgSignalRTransitionFromJson(json);
}

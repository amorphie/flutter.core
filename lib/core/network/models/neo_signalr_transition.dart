/*
 * neo_core
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

part 'neo_signalr_transition.g.dart';

@JsonSerializable(createToJson: false)
class NeoSignalRTransition extends Equatable {
  @JsonKey(name: "transition")
  final String transitionId;

  @JsonKey(name: "state", defaultValue: "")
  final String state;

  @JsonKey(name: "viewSource", defaultValue: "")
  final String viewSource;

  @JsonKey(name: "page", defaultValue: {})
  final Map<String, dynamic> pageDetails;

  @JsonKey(name: "data", defaultValue: {})
  final Map<String, dynamic> initialData;

  @JsonKey(name: "additionalData", defaultValue: null)
  final Map<String, dynamic>? additionalData;

  @JsonKey(name: "message")
  final String? statusMessage;

  @JsonKey(name: "errorCode")
  final String? statusCode;

  @JsonKey(name: "buttonType")
  final String? buttonType;

  @JsonKey(name: "time")
  final DateTime time;

  const NeoSignalRTransition({
    required this.transitionId,
    required this.state,
    required this.viewSource,
    required this.pageDetails,
    required this.initialData,
    required this.buttonType,
    required this.time,
    this.statusMessage,
    this.statusCode,
    this.additionalData,
  });

  @override
  List<Object?> get props => [
        transitionId,
        state,
        viewSource,
        pageDetails,
        initialData,
        additionalData,
        statusMessage,
        statusCode,
        buttonType,
        time,
      ];

  factory NeoSignalRTransition.fromJson(Map<String, dynamic> json) => _$NeoSignalRTransitionFromJson(json);
}

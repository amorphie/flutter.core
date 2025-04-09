/*
 * neo_core
 *
 * Created on 18/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'http_active_host.g.dart';

abstract class _Constants {
  static const keyHost = 'host';
  static const keyRetryCount = 'retry-count';
}

@JsonSerializable(createToJson: false)
class HttpActiveHost extends Equatable {
  @JsonKey(name: _Constants.keyHost, defaultValue: "")
  final String host;

  @JsonKey(name: _Constants.keyRetryCount, defaultValue: 0)
  final int retryCount;

  const HttpActiveHost({required this.host, required this.retryCount});

  factory HttpActiveHost.fromJson(Map<String, dynamic> json) => _$HttpActiveHostFromJson(json);

  String encode() {
    return jsonEncode({
      _Constants.keyHost: host,
      _Constants.keyRetryCount: retryCount,
    });
  }

  factory HttpActiveHost.decode(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return HttpActiveHost.fromJson(json);
  }

  @override
  List<Object?> get props => [host, retryCount];
}

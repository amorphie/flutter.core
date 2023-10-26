/*
 * neo_core
 *
 * Created on 26/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:json_annotation/json_annotation.dart';

part 'http_auth_response.g.dart';

@JsonSerializable(createToJson: false)
class HttpAuthResponse {
  @JsonKey(name: 'access_token', defaultValue: "")
  final String token;

  @JsonKey(name: 'refresh_token', defaultValue: "")
  final String refreshToken;

  @JsonKey(name: 'expires_in')
  final int? expiresInSeconds;

  const HttpAuthResponse({required this.token, required this.refreshToken, this.expiresInSeconds});

  factory HttpAuthResponse.fromJson(Map<String, dynamic> json) => _$HttpAuthResponseFromJson(json);
}

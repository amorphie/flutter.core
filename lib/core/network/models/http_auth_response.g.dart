// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HttpAuthResponse _$HttpAuthResponseFromJson(Map<String, dynamic> json) =>
    HttpAuthResponse(
      token: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      expiresInSeconds: (json['expires_in'] as num?)?.toInt() ?? 0,
      refreshTokenExpiresInSeconds:
          (json['refresh_token_expires_in'] as num?)?.toInt() ?? 0,
    );

/*
 * neo_core
 *
 * Created on 20/11/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'dart:convert';

/// Taken From: https://pub.dev/packages/jwt_decoder
class JwtDecoder {
  JwtDecoder._();

  static Map<String, dynamic> decode(String token) {
    final splitToken = token.split(".");
    if (splitToken.length != 3) {
      throw const FormatException('Invalid token');
    }
    try {
      final payloadBase64 = splitToken[1];
      final normalizedPayload = base64.normalize(payloadBase64);
      final payloadString = utf8.decode(base64.decode(normalizedPayload));
      final decodedPayload = jsonDecode(payloadString);

      return decodedPayload;
    } catch (_) {
      throw const FormatException('Invalid payload');
    }
  }

  /// Decode a string JWT token into a `Map<String, dynamic>`
  /// containing the decoded JSON payload.
  ///
  /// Note: header and signature are not returned by this method.
  ///
  /// Returns null if the token is not valid
  static Map<String, dynamic>? tryDecode(String token) {
    try {
      return decode(token);
    } catch (_) {
      return null;
    }
  }
}

import 'package:neo_core/core/encryption/jwt_decoder.dart';

class TokenUtil {
  TokenUtil._();

  static bool is2FAToken(String token) {
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final isTwoFactorAuthenticated = decodedToken["clientAuthorized"] != "1" && decodedToken["role"] != "non-customer";
    return isTwoFactorAuthenticated;
  }
}

/*
 * neo_core
 *
 * Created on 21/12/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

abstract class NeoNetworkHeaderKey {
  static const contentType = "Content-Type";
  static const acceptLanguage = "Accept-Language";
  static const contentLanguage = "Content-Language";
  static const application = "X-Application";
  static const deployment = "X-Deployment";
  static const deviceId = "X-Device-Id";
  static const tokenId = "X-Token-Id";
  static const requestId = "X-Request-Id";
  static const deviceInfo = "X-Device-Info";
  static const authorization = "Authorization";
  static const user = "User";
  static const behalfOfUser = "Behalf-Of-User";
  static const accessToken = "access_token";
}

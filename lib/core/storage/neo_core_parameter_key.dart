/*
 * 
 * neo_bank
 * 
 * Created on 30/01/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 * 
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 * 
 */

abstract class NeoCoreParameterKey {
  /// Parameter key format is below:
  /// [Source]:[Scope]:[Parameter Name]
  /// TODO: Sort keys alphabetically
  static const secureStorageAuthToken = "secureStorage:infrastructure:authToken";
  static const secureStorageBusinessLine = "secureStorage:common:businessLine";
  static const secureStorageCustomerId = "secureStorage:common:customerId";
  static const secureStorageCustomerName = "secureStorage:common:customerName";
  static const secureStorageCustomerNameAndSurname = "secureStorage:common:customerNameAndSurname";
  static const secureStorageCustomerNo = "secureStorage:common:customerNo";
  static const secureStorageCustomerSurname = "secureStorage:common:customerSurname";
  static const secureStorageCustomerNameAndSurnameUppercase = "secureStorage:common:customerNameAndSurnameUppercase";
  static const secureStorageDeviceId = "secureStorage:infrastructure:deviceIdV2";
  static const secureStorageDeviceInfo = "secureStorage:infrastructure:deviceInformation";
  static const secureStorageDeviceRegistrationToken = "secureStorage:infrastructure:deviceRegistrationToken";
  static const secureStorageEmail = "secureStorage:common:email";
  static const secureStorageInstallationId = "secureStorage:infrastructure:installationId";
  static const secureStorageLanguage = "secureStorage:common:language";
  static const secureStorageMtlsClientCertificate = "secureStorage:mtls:clientCertificate";
  static const secureStorageMtlsPrivateKey = "secureStorage:mtls:privateKey";
  static const secureStoragePhoneNumber = "secureStorage:common:phoneNumber";
  static const secureStorageRefreshToken = "secureStorage:infrastructure:refreshToken";
  static const secureStorageSessionId = "secureStorage:infrastructure:sessionId";
  static const secureStorageUserId = "secureStorage:infrastructure:userId";
  static const secureStorageUserInfoIsMobUnapproved = "secureStorage:infrastructure:userInfoIsMobUnapproved";
  static const secureStorageUserRole = "secureStorage:infrastructure:userRole";

  static const sharedPrefsAuthStatus = "shared_pref_key_auth_status";
  static const sharedPrefsIsHuaweiCompatible = "sharedPrefs:common:sharedPrefsIsHuaweiCompatible";
  static const sharedPrefsIsQAHostSelected = "sharedPrefs:infrastructure:isQAHostSelected";
  static const sharedPrefsLanguageCode = "sharedPrefs:common:languageCode";
}

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
  static const secureStorageCustomerNameAndSurname = "secureStorage:common:customerNameAndSurname";
  static const secureStorageDeviceId = "secureStorage:infrastructure:deviceId";
  static const secureStorageDeviceInfo = "secureStorage:infrastructure:deviceInformation";
  static const secureStorageDeviceRegistrationToken = "secureStorage:infrastructure:deviceRegistrationToken";
  static const secureStorageLanguage = "secureStorage:common:language";
  static const secureStorageRefreshToken = "secureStorage:infrastructure:refreshToken";
  static const secureStorageTokenId = "secureStorage:infrastructure:tokenId";

  static const sharedPrefsFirstRun = "sharedPrefs:infrastructure:firstRun";
  static const sharedPrefsLanguageCode = "sharedPrefs:common:languageCode";
}

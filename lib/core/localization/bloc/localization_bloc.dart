/*
 * neo_bank
 *
 * Created on 4/10/2023.
 * Copyright (c) 2023 BurganBank. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of BurganBank.
 * Any reproduction of this material must contain this notice.
 */

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:interpolation/interpolation.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/localization/language.dart';
import 'package:neo_core/core/managers/parameter_manager/neo_core_parameter_key.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/transformers/debounce_sequential_transformer.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';
import 'package:neo_core/neo_core.dart';

export 'package:neo_core/core/localization/language.dart';

part 'localization_event.dart';
part 'localization_state.dart';

abstract class _Constants {
  static const localizationEndpoint = "get-localization";
  static const headerParameterKeyIsOnApp = "IsOnApp";
  static const headerParameterKeyDigest = "Digest";
  static const debounceDuration = Duration(milliseconds: 200);
}

class LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> {
  static Language? _currentLanguage;

  static Language? get currentLanguage => _currentLanguage;

  static Map<String, dynamic> localizationData = {};

  final bool isOnApp;
  final _neoSharedPrefs = getIt.get<NeoSharedPrefs>();
  final _neoNetworkManager = getIt.get<NeoNetworkManager>();
  final bool fetchLocalizationFromApi;

  LocalizationBloc({required this.isOnApp, this.fetchLocalizationFromApi = true})
      : super(LocalizationState(Language.defaultLanguage)) {
    on<LocalizationEventChangeLanguage>(_onLanguageChangedToState);
    on<LocalizationEventSwitchLanguage>(
      _onSwitchLanguage,
      transformer: debounceSequencial(_Constants.debounceDuration),
    );
    on<LocalizationEventFetchLocalizationFromAPI>(_onFetchLocalizationFromAPI);
    _init();
  }

  static String? getMaybeLocalizedText(String key) {
    final localizationItem = localizationData[key];
    return localizationItem?[_currentLanguage?.languageCode.toUpperCase()];
  }

  void _init() {
    final language = _getStoredLanguage();
    _currentLanguage = language;
    add(LocalizationEventChangeLanguage(language));
    if (fetchLocalizationFromApi) {
      add(LocalizationEventFetchLocalizationFromAPI());
    }
  }

  _onLanguageChangedToState(LocalizationEventChangeLanguage event, Emitter<LocalizationState> emit) async {
    final targetLanguage = event.language;
    await _neoSharedPrefs.write(NeoCoreParameterKey.sharedPrefsLanguageCode, targetLanguage.languageCode);
    _currentLanguage = targetLanguage;
    emit(state.copyWith(language: targetLanguage));
  }

  _onSwitchLanguage(LocalizationEventSwitchLanguage event, Emitter<LocalizationState> emit) async {
    final targetLanguage = LocalizationBloc.currentLanguage == Language.english ? Language.turkish : Language.english;
    await _neoSharedPrefs.write(NeoCoreParameterKey.sharedPrefsLanguageCode, targetLanguage.languageCode);
    _currentLanguage = targetLanguage;
    emit(state.copyWith(language: targetLanguage));
  }

  /// Returns the language to be used by the application.
  ///
  /// First checks for a stored language preference in SharedPreferences.
  /// If no stored preference exists, falls back to the default language.
  ///
  /// @return Language The language to be used by the application
  Language _getStoredLanguage() {
    final storedLanguageCode = _neoSharedPrefs.read(NeoCoreParameterKey.sharedPrefsLanguageCode);
    // If there's a valid stored language code in preferences, use it
    if (storedLanguageCode != null && storedLanguageCode is String) {
      return Language.fromString(storedLanguageCode);
    }
    return Language.defaultLanguage;
  }

  _onFetchLocalizationFromAPI(event, Emitter<LocalizationState> emit) async {
    final localizationDigest = _neoSharedPrefs.read(NeoCoreParameterKey.sharedPrefsLocalizationResponseDigest);
    try {
      final response = await _neoNetworkManager.call(
        NeoHttpCall(
          endpoint: _Constants.localizationEndpoint,
          headerParameters: {
            _Constants.headerParameterKeyIsOnApp: isOnApp.toString(),
            _Constants.headerParameterKeyDigest: localizationDigest != null ? localizationDigest as String : "",
          },
        ),
      );

      // Use local data when response is 204
      if (response.isError || response.asSuccess.data.isEmpty) {
        _loadLocalizationResponseFromStorage(emit);
        return;
      }
      final responseDigest = response.asSuccess.data["checksum"];
      final responseLocalizationBase64 = response.asSuccess.data["file"];
      if (responseDigest != null) {
        await _neoSharedPrefs.write(NeoCoreParameterKey.sharedPrefsLocalizationResponseDigest, responseDigest);
      }
      if (responseLocalizationBase64 != null) {
        await _neoSharedPrefs.write(
          NeoCoreParameterKey.sharedPrefsLocalizationResponseBase64,
          responseLocalizationBase64,
        );
        localizationData = json.decode(utf8.decode(base64Decode(responseLocalizationBase64)));
        emit(state.copyWith(lastUpdatedTime: DateTime.now()));
      }
    } catch (e) {
      getIt.getIfReady<NeoLogger>()?.logError("[LocalizationBloc] Error: $e");
    }
  }

  void _loadLocalizationResponseFromStorage(Emitter<LocalizationState> emit) {
    final localizationDataBase64 = _neoSharedPrefs.read(
      NeoCoreParameterKey.sharedPrefsLocalizationResponseBase64,
    );
    if (localizationDataBase64 != null && localizationDataBase64 is String) {
      localizationData = json.decode(utf8.decode(base64Decode(localizationDataBase64)));
      emit(state.copyWith(lastUpdatedTime: DateTime.now()));
    }
  }

  static void addLocalization(String key, Map<String, String> translations) {
    if (key.isEmpty || translations.isEmpty) {
      debugPrint('[LocalizationBloc] Warning: Attempted to add empty key or translations');
      return;
    }

    localizationData[key] = Map<String, String>.from(translations);
  }
}

/// It takes a localization key and returns the localized text if it exists.
/// Prefer to use [localize] method.
/// It is very similar to [localize] method but instead of returning key itself,
/// it returns null if the localization key does not exist. This method is useful to
/// check if the localization key is provided. (It is required for bussiness logic)
/// ---
/// Global function for localization which does not need context
/// It should be used in components such as NeoText which takes localization key from response
/// DO NOT USE THIS METHOD FOR LOCAL USAGE OR DON'T MAKE THIS METHOD A STRING EXTENSION.
/// PREFER loc() method in [LocalizationKeyExtension] whenever possible
String? maybeLocalize(String localizationKey, {Map<String, Object>? params}) {
  final localized = LocalizationBloc.getMaybeLocalizedText(localizationKey);
  if (localized == null || params == null) {
    return localized;
  }
  return Interpolation().eval(localized, params);
}

/// Global function for localization which does not need context
/// It should be used in components such as NeoText which takes localization key from response
/// DO NOT USE THIS METHOD FOR LOCAL USAGE OR DON'T MAKE THIS METHOD A STRING EXTENSION.
/// PREFER loc() method in [LocalizationKeyExtension] whenever possible
String localize(String localizationKey, {Map<String, Object>? params}) {
  return maybeLocalize(localizationKey, params: params) ?? localizationKey;
}

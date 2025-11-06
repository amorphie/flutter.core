import 'dart:convert';

import 'package:flutter_shield/secure_enclave.dart';
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/isolates/execute_isolated.dart';
import 'package:neo_core/core/isolates/isolate_data.dart';
import 'package:neo_core/core/network/models/neo_signalr_event.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/bloc/neo_transition_listener_bloc.dart';

abstract class _Constants {
  static const loginCertificateState = "amorphie-mobile-login-certificate-flow";
  static const loginSendCertificateTransitionName = "amorphie-mobile-login-send-certificate";
  static const loginSendCertificateMissingDataTransitionName = "amorphie-mobile-login-certificate-missing-data";
}

class ProcessLoginCertificateSilentEventUseCase {
  NeoLogger get _neoLogger => GetIt.I.get();

  Future<void> call(NeoSignalREvent event, NeoTransitionListenerBloc bloc, NeoCoreSecureStorage secureStorage) async {
    if (event.transition.state != _Constants.loginCertificateState) {
      return;
    }
    final userReference = event.transition.additionalData!["Reference"] as String?;

    if (userReference == null) {
      _triggerMissingDataTransition(
        bloc,
        "[ProcessLoginCertificateSilentEventUseCase][_triggerMissingDataTransition] User reference is null.",
      );
      return;
    }

    final deviceId = await secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId);
    if (deviceId == null) {
      _triggerMissingDataTransition(
        bloc,
        "[ProcessLoginCertificateSilentEventUseCase][_triggerMissingDataTransition] Device id is null.",
      );
      return;
    }

    final publicKey = await executeIsolated<String?>(_process, IsolateData([userReference, deviceId]));
    if (publicKey == null) {
      _triggerMissingDataTransition(
        bloc,
        "[ProcessLoginCertificateSilentEventUseCase][_triggerMissingDataTransition] Public key is null. $deviceId",
      );
      return;
    }

    bloc.add(
      NeoTransitionListenerEventPostTransition(
        transitionName: _Constants.loginSendCertificateTransitionName,
        body: {
          "Certificate": {
            "publicKey": publicKey,
            "commonName": "$userReference.burgan.com.tr",
          },
        },
      ),
    );
  }

  void _triggerMissingDataTransition(NeoTransitionListenerBloc bloc, String errorMessage) {
    _neoLogger.logError(errorMessage);

    bloc.add(
      NeoTransitionListenerEventPostTransition(
        transitionName: _Constants.loginSendCertificateMissingDataTransitionName,
        body: {
          "CertificateErrorMessage": errorMessage,
        },
      ),
    );
  }

  Future<String?> _process(IsolateData data) async {
    try {
      final userReference = data.data[0];
      final deviceId = data.data[1];
      final secureEnclavePlugin = SecureEnclave();
      final clientKeyTag = "$deviceId$userReference";

      final isKeyCreated = (await secureEnclavePlugin.isKeyCreated(clientKeyTag, "C")).value ?? false;
      if (!isKeyCreated) {
        await secureEnclavePlugin.generateKeyPair(
          accessControl: AccessControlModel(
            options: [AccessControlOption.privateKeyUsage],
            tag: clientKeyTag,
          ),
        );
      }

      final publicKeyResponse = await secureEnclavePlugin.getPublicKey(clientKeyTag);
      final publicKey = publicKeyResponse.value;

      if (publicKey == null) {
        return null;
      }

      return base64Encode(utf8.encode(publicKey));
    } catch (e) {
      _neoLogger.logError(e.toString());
      return null;
    }
  }
}

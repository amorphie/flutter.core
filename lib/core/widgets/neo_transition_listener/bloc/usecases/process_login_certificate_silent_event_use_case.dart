import 'dart:convert';

import 'package:flutter_shield/secure_enclave.dart';
import 'package:neo_core/core/isolates/execute_isolated.dart';
import 'package:neo_core/core/isolates/isolate_data.dart';
import 'package:neo_core/core/network/models/neo_signalr_event.dart';
import 'package:neo_core/core/util/device_util/device_util.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/bloc/neo_transition_listener_bloc.dart';

class ProcessLoginCertificateSilentEventUseCase {
  Future<void> call(NeoSignalREvent event, NeoTransitionListenerBloc bloc) async {
    if (event.transition.state != "amorphie-mobile-login-certificate-flow") {
      return;
    }
    final userReference = event.transition.additionalData!["Reference"] as String;
    final publicKey = await executeIsolated(_process, IsolateData(userReference));
    if (publicKey == null) {
      return;
    }

    bloc.add(
      NeoTransitionListenerEventPostTransition(
        transitionName: 'amorphie-mobile-login-send-certificate',
        body: {
          "Certificate": {
            "publicKey": publicKey,
            "commonName": "$userReference.burgan.com",
          },
        },
      ),
    );
  }

  Future<String?> _process(IsolateData data) async {
    final userReference = data.data;
    final secureEnclavePlugin = SecureEnclave();
    final deviceId = await DeviceUtil().getDeviceId();
    final clientKeyTag = "$deviceId$userReference";

    final isKeyCreated = (await secureEnclavePlugin.isKeyCreated(clientKeyTag, "C")).value ?? false;
    if (!isKeyCreated) {
      await secureEnclavePlugin.generateKeyPair(
        accessControl: AccessControlModel(
          options: [AccessControlOption.privateKeyUsage],
          tag: "$deviceId$userReference",
        ),
      );
    }

    final publicKeyResponse = await secureEnclavePlugin.getPublicKey(clientKeyTag);
    final publicKey = publicKeyResponse.value;

    if (publicKey == null) {
      return null;
    }

    return base64Encode(utf8.encode(publicKey));
  }
}

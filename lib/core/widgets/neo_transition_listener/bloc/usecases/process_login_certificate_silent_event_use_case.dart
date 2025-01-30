import 'dart:convert';

import 'package:flutter_shield/secure_enclave.dart';
import 'package:neo_core/core/network/models/neo_signalr_event.dart';
import 'package:neo_core/core/util/device_util/device_util.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/bloc/neo_transition_listener_bloc.dart';

class ProcessLoginCertificateSilentEventUseCase {
  final _secureEnclavePlugin = SecureEnclave();

  Future<void> call(NeoSignalREvent event, NeoTransitionListenerBloc bloc) async {
    if (event.transition.state != "amorphie-mobile-login-certificate-flow") {
      return;
    }
    final userReference = event.transition.additionalData!["Reference"] as String;
    final deviceId = await DeviceUtil().getDeviceId();
    final clientKeyTag = "$deviceId$userReference";

    final isKeyCreated = (await _secureEnclavePlugin.isKeyCreated(clientKeyTag, "C")).value ?? false;
    if (!isKeyCreated) {
      await _secureEnclavePlugin.generateKeyPair(
        accessControl: AccessControlModel(
          options: [AccessControlOption.privateKeyUsage],
          tag: "$deviceId$userReference",
        ),
      );
    }

    final publicKeyResponse = await _secureEnclavePlugin.getPublicKey(clientKeyTag);
    final publicKey = publicKeyResponse.value;
    if (publicKey == null) {
      return;
    }

    bloc.add(
      NeoTransitionListenerEventPostTransition(
        transitionName: 'amorphie-mobile-login-send-certificate',
        body: {
          "Certificate": {
            "publicKey": base64Encode(utf8.encode(publicKey)),
            "commonName": "$userReference.burgan.com",
          }
        },
      ),
    );
  }
}

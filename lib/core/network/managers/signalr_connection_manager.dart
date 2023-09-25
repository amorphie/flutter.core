/*
 * burgan_core
 *
 * Created on 22/9/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'dart:convert';

import 'package:burgan_core/core/network/models/brg_signalr_transition.dart';
import 'package:collection/collection.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalrConnectionManager {
  final String serverUrl;
  final String methodName;
  late HubConnection _hubConnection;

  SignalrConnectionManager({
    required this.serverUrl,
    required this.methodName,
  });

  Future<void> init({Function(String navigationPath)? onPageNavigation}) async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl)
        .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 20000]).build();
    _hubConnection.onclose(({error}) => print('onclose called'));
    _hubConnection.onreconnecting(({error}) => print("onreconnecting called"));
    _hubConnection.onreconnected(({connectionId}) => print("onreconnected called"));

    if (_hubConnection.state != HubConnectionState.Connected) {
      await _hubConnection.start();
    }
  }

  void listenForTransitionEvents({
    required String transitionId,
    required Function(String navigationPath) onPageNavigation,
    Function(String token)? onTokenRetrieved,
    Function(String errorMessage)? onError,
  }) {
    _hubConnection.on(methodName, (List<Object?>? transitions) {
      print('SignalR Response: $transitions');
      if (transitions == null) {
        return;
      }
      final ongoingTransition = transitions
          .map((transition) {
            try {
              return BrgSignalRTransition.fromJson(jsonDecode(transition as String));
            } catch (e) {
              return null;
            }
          })
          .where((element) => element != null)
          .toList()
          .firstWhereOrNull((transition) => transition?.transitionId == transitionId);

      final String? token = ongoingTransition?.additionalData?["access_token"];
      print('Additional data is ${ongoingTransition?.additionalData}');
      print('Token is $token');
      if (onTokenRetrieved != null && token != null && token.isNotEmpty) {
        onTokenRetrieved(token);
      }

      final isNavigationAllowed = ongoingTransition?.pageDetails["operation"] == "Open";
      final navigationPath = ongoingTransition?.pageDetails["pageRoute"]?["label"] as String?;
      if (isNavigationAllowed && navigationPath != null) {
        onPageNavigation(navigationPath);
      } else if ((ongoingTransition?.errorMessage.isNotEmpty ?? false) && onError != null) {
        onError(ongoingTransition!.errorMessage);
      }
    });
  }

  void stop() {
    _hubConnection.stop();
  }
}

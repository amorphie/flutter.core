/*
 * neo_core
 *
 * Created on 5/2/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/network/neo_network.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:uuid/uuid.dart';

part 'neo_transition_listener_event.dart';
part 'neo_transition_listener_state.dart';

class NeoTransitionListenerBloc extends Bloc<NeoTransitionListenerEvent, NeoTransitionListenerState> {
  late final NeoCoreSecureStorage neoCoreSecureStorage = NeoCoreSecureStorage();
  late NeoWorkflowManager neoWorkflowManager;
  SignalrConnectionManager? signalrConnectionManager;

  NeoTransitionListenerBloc() : super(NeoTransitionListenerState()) {
    on<NeoTransitionListenerEventInit>((event, emit) => _onInit(event));
    on<NeoTransitionListenerEventStartTransition>((event, emit) => _onStartTransition(event));
    on<NeoTransitionListenerEventPostTransition>((event, emit) => _onPostTransition(event));
  }

  Future<void> _onInit(NeoTransitionListenerEventInit event) async {
    neoWorkflowManager = NeoWorkflowManager(event.neoNetworkManager);
    signalrConnectionManager = SignalrConnectionManager(
      serverUrl: event.signalRServerUrl + await _getWorkflowQueryParameters(),
      methodName: event.signalRMethodName,
    );
    await signalrConnectionManager?.init();
    signalrConnectionManager?.listenForTransitionEvents(
      onTransition: (NeoSignalRTransition transition) {
        _retrieveTokenIfExist(transition, event.onLoggedInSuccessfully);
        _handleTransitionNavigation(
          ongoingTransition: transition,
          onPageNavigation: event.onPageNavigation,
          onError: event.onError,
        );
      },
    );
  }

  Future<String> _getWorkflowQueryParameters() async {
    final secureStorage = NeoCoreSecureStorage();
    final results = await Future.wait([
      secureStorage.getDeviceId(),
      secureStorage.getTokenId(),
      secureStorage.getAuthToken(),
    ]);

    final deviceId = results[0] ?? "";
    final tokenId = results[1] ?? "";
    final authToken = results[2] ?? "";

    return "?${NeoNetworkHeaderKey.deviceId}=$deviceId&"
        "${NeoNetworkHeaderKey.tokenId}=$tokenId&"
        "${NeoNetworkHeaderKey.requestId}=${const Uuid().v1()}&"
        "${NeoNetworkHeaderKey.accessToken}=$authToken";
  }

  void _onStartTransition(NeoTransitionListenerEventStartTransition event) {
    NeoWorkflowManager.resetInstanceId();
  }

  Future<void> _onPostTransition(NeoTransitionListenerEventPostTransition event) async {
    await neoWorkflowManager.postTransition(transitionName: event.transitionName, body: event.body);
  }

  void _retrieveTokenIfExist(NeoSignalRTransition ongoingTransition, VoidCallback? onLoggedInSuccessfully) {
    final String? token = ongoingTransition.additionalData?["access_token"];
    final String? refreshToken = ongoingTransition.additionalData?["refresh_token"];
    if (token != null && token.isNotEmpty) {
      neoCoreSecureStorage
        ..setAuthToken(token)
        ..setRefreshToken(refreshToken ?? "");
      onLoggedInSuccessfully?.call();
    }
  }

  void _handleTransitionNavigation({
    required NeoSignalRTransition ongoingTransition,
    required Function(SignalrTransitionData navigationData) onPageNavigation,
    required Function(String errorMessage)? onError,
  }) {
    final isNavigationAllowed = ongoingTransition.pageDetails["operation"] == "Open";
    final navigationPath = ongoingTransition.pageDetails["pageRoute"]?["label"] as String?;
    final navigationType = ongoingTransition.pageDetails["type"] as String?;
    final isBackNavigation = ongoingTransition.buttonType == "Back";
    if (isNavigationAllowed && navigationPath != null) {
      onPageNavigation(
        SignalrTransitionData(
          navigationPath: navigationPath,
          navigationType: NeoNavigationType.fromJson(navigationType ?? ""),
          pageId: ongoingTransition.pageId,
          viewSource: ongoingTransition.viewSource,
          initialData: ongoingTransition.additionalData ?? {},
          isBackNavigation: isBackNavigation,
        ),
      );
    } else if ((ongoingTransition.errorMessage.isNotEmpty) && onError != null) {
      onError(ongoingTransition.errorMessage);
    }
  }

  @override
  Future<void> close() {
    signalrConnectionManager?.stop();
    return super.close();
  }
}

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

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/network/neo_network.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/mixins/neo_transition_bus_mixin.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/usecases/get_workflow_query_parameters_usecase.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';

part 'neo_transition_listener_event.dart';
part 'neo_transition_listener_state.dart';

abstract class _Constants {
  static const defaultErrorCode = "400";
}

class NeoTransitionListenerBloc extends Bloc<NeoTransitionListenerEvent, NeoTransitionListenerState>
    with NeoTransitionBus {
  late final NeoCoreSecureStorage neoCoreSecureStorage = NeoCoreSecureStorage();
  late final Function(SignalrTransitionData navigationData) onPageNavigation;
  late final VoidCallback? onLoggedInSuccessfully;
  late final Function(NeoError error)? onTransitionError;
  late final Function({required bool displayLoading}) onLoadingStatusChanged;

  NeoTransitionListenerBloc() : super(NeoTransitionListenerState()) {
    on<NeoTransitionListenerEventInit>((event, emit) => _onInit(event));
    on<NeoTransitionListenerEventPostTransition>((event, emit) => _onPostTransition(event));
  }

  Future<void> _onInit(NeoTransitionListenerEventInit event) async {
    onPageNavigation = event.onPageNavigation;
    onLoggedInSuccessfully = event.onLoggedInSuccessfully;
    onTransitionError = event.onError;
    onLoadingStatusChanged = event.onLoadingStatusChanged;

    await initTransitionBus(
      neoWorkflowManager: NeoWorkflowManager(event.neoNetworkManager),
      signalrServerUrl: event.signalRServerUrl + await GetWorkflowQueryParametersUseCase().call(),
      signalrMethodName: event.signalRMethodName,
    );
  }

  Future<void> _onPostTransition(NeoTransitionListenerEventPostTransition event) async {
    try {
      onLoadingStatusChanged(displayLoading: true);
      final transitionResponse = await postTransition(event.transitionName, event.body);
      await _retrieveTokenIfExist(transitionResponse);
      onLoadingStatusChanged(displayLoading: false);
      _handleTransitionNavigation(ongoingTransition: transitionResponse);
    } catch (e) {
      onLoadingStatusChanged(displayLoading: false);
      onTransitionError?.call(NeoError.defaultError());
    }
  }

  Future<void> _retrieveTokenIfExist(NeoSignalRTransition ongoingTransition) async {
    final String? token = ongoingTransition.additionalData?["access_token"];
    final String? refreshToken = ongoingTransition.additionalData?["refresh_token"];
    if (token != null && token.isNotEmpty) {
      await neoCoreSecureStorage.setAuthToken(token);
      await neoCoreSecureStorage.setRefreshToken(refreshToken ?? "");
      onLoggedInSuccessfully?.call();
    }
  }

  void _handleTransitionNavigation({required NeoSignalRTransition ongoingTransition}) {
    final isNavigationAllowed = ongoingTransition.pageDetails["operation"] == "Open";
    final navigationPath = ongoingTransition.pageDetails["pageRoute"]?["label"] as String?;
    final navigationType = ongoingTransition.pageDetails["type"] as String?;
    final isBackNavigation = ongoingTransition.buttonType == "Back";
    final errorMessage = ongoingTransition.errorMessage;

    if (isNavigationAllowed && navigationPath != null) {
      onPageNavigation(
        SignalrTransitionData(
          navigationPath: navigationPath,
          navigationType: NeoNavigationType.fromJson(navigationType ?? ""),
          pageId: ongoingTransition.state,
          viewSource: ongoingTransition.viewSource,
          initialData: ongoingTransition.additionalData ?? {},
          isBackNavigation: isBackNavigation,
        ),
      );
    } else if (errorMessage != null && errorMessage.isNotEmpty) {
      // TODO: Pass error message to onTransitionError callback
      onTransitionError?.call(NeoError(responseCode: ongoingTransition.errorCode ?? _Constants.defaultErrorCode));
    }
  }
}

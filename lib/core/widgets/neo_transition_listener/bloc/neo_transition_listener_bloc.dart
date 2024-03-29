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
import 'package:neo_core/core/navigation/models/ekyc_event_data.dart';
import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/network/neo_network.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/mixins/neo_transition_bus_mixin.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/usecases/get_workflow_query_parameters_usecase.dart';
import 'package:neo_core/core/workflow_form/neo_sub_workflow_manager.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';

part 'neo_transition_listener_event.dart';
part 'neo_transition_listener_state.dart';

class NeoTransitionListenerBloc extends Bloc<NeoTransitionListenerEvent, NeoTransitionListenerState>
    with NeoTransitionBus {
  late final NeoCoreSecureStorage neoCoreSecureStorage = NeoCoreSecureStorage();
  late final Function(SignalrTransitionData navigationData) onTransitionSuccess;
  late final Function(EkycEventData ekycData) onEkycEvent;
  late final Function(NeoError error)? onTransitionError;
  late final VoidCallback? onLoggedInSuccessfully;
  late final Function({required bool displayLoading}) onLoadingStatusChanged;

  NeoTransitionListenerBloc() : super(NeoTransitionListenerState()) {
    on<NeoTransitionListenerEventInit>((event, emit) => _onInit(event));
    on<NeoTransitionListenerEventPostTransition>((event, emit) => _onPostTransition(event));
  }

  @override
  Future<Map<String, dynamic>> initWorkflow({
    required String workflowName,
    String? suffix,
    String? instanceId,
    bool isSubFlow = false,
  }) async {
    try {
      onLoadingStatusChanged(displayLoading: true);
      return await super.initWorkflow(
        workflowName: workflowName,
        suffix: suffix,
        instanceId: instanceId,
        isSubFlow: isSubFlow,
      );
    } catch (e) {
      rethrow;
    } finally {
      onLoadingStatusChanged(displayLoading: false);
    }
  }

  Future<void> _onInit(NeoTransitionListenerEventInit event) async {
    onTransitionSuccess = event.onTransitionSuccess;
    onEkycEvent = event.onEkycEvent;
    onLoggedInSuccessfully = event.onLoggedInSuccessfully;
    onTransitionError = event.onTransitionError;
    onLoadingStatusChanged = event.onLoadingStatusChanged;

    await initTransitionBus(
      neoWorkflowManager: event.neoWorkflowManager,
      neoSubWorkflowManager: event.neoSubWorkflowManager,
      signalrServerUrl: event.signalRServerUrl + await GetWorkflowQueryParametersUseCase().call(),
      signalrMethodName: event.signalRMethodName,
    );
  }

  Future<void> _onPostTransition(NeoTransitionListenerEventPostTransition event) async {
    try {
      onLoadingStatusChanged(displayLoading: true);
      final transitionResponse = await postTransition(event.transitionName, event.body, isSubFlow: event.isSubFlow);
      await _retrieveTokenIfExist(transitionResponse);
      onLoadingStatusChanged(displayLoading: false);
      await _handleTransitionResult(ongoingTransition: transitionResponse);
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
      await neoCoreSecureStorage.write(key: NeoCoreParameterKey.secureStorageRefreshToken, value: refreshToken ?? "");
      onLoggedInSuccessfully?.call();
    }
  }

  Future<void> _handleTransitionResult({required NeoSignalRTransition ongoingTransition}) async {
    final navigationPath = ongoingTransition.pageDetails["pageRoute"]?["label"] as String?;
    final navigationType = ongoingTransition.pageDetails["type"] as String?;
    final isBackNavigation = ongoingTransition.buttonType == "Back";
    final transitionId = ongoingTransition.transitionId;
    final isEkyc = ongoingTransition.additionalData != null && ongoingTransition.additionalData?["isEkyc"] == true;
    if (isEkyc) {
      final ekycState = ongoingTransition.additionalData?["state"] as String;
      final message = ongoingTransition.additionalData?["message"] as String;
      onEkycEvent(EkycEventData(state: ongoingTransition.state, ekycState: ekycState, message: message));
    } else {
      onTransitionSuccess(
        SignalrTransitionData(
          navigationPath: navigationPath,
          navigationType: NeoNavigationType.fromJson(navigationType ?? ""),
          pageId: ongoingTransition.state,
          viewSource: ongoingTransition.viewSource,
          initialData: {
            ...ongoingTransition.additionalData ?? {},
            ...ongoingTransition.initialData,
          },
          isBackNavigation: isBackNavigation,
          transitionId: await getAvailableTransitionId(ongoingTransition) ?? transitionId,
          statusCode: ongoingTransition.statusCode,
          statusMessage: ongoingTransition.statusMessage,
        ),
      );
    }
  }
}

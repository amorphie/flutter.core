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

import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neo_core/core/analytics/neo_posthog.dart';
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
import 'package:universal_io/io.dart';

part 'neo_transition_listener_event.dart';

part 'neo_transition_listener_state.dart';

class NeoTransitionListenerBloc extends Bloc<NeoTransitionListenerEvent, NeoTransitionListenerState>
    with NeoTransitionBus {
  final NeoCoreSecureStorage neoCoreSecureStorage;
  late final Function(SignalrTransitionData navigationData) onTransitionSuccess;
  late final Function(EkycEventData ekycData) onEkycEvent;
  late final Function(NeoError error)? onTransitionError;
  late final Function({required bool isTwoFactorAuthenticated})? onLoggedInSuccessfully;
  late final Function({required bool displayLoading}) onLoadingStatusChanged;

  /// Determines whether multiple transitions can occur at the same time.
  ///
  /// If [allowParallelTransitions] is set to false, transition event is
  /// triggered while another transition event is still being processed,
  /// the new transition request will be dropped and will not be processed.
  final bool allowParallelTransitions;

  NeoTransitionListenerBloc({
    required this.neoCoreSecureStorage,
    this.allowParallelTransitions = false,
  }) : super(NeoTransitionListenerState()) {
    on<NeoTransitionListenerEventInit>((event, emit) => _onInit(event));
    on<NeoTransitionListenerEventInitWorkflow>(
      (event, emit) => _onInitWorkflow(event),
      transformer: allowParallelTransitions ? null : droppable(),
    );
    on<NeoTransitionListenerEventPostTransition>(
      (event, emit) => _onPostTransition(event),
      transformer: allowParallelTransitions ? null : droppable(),
    );
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
      neoPosthog: event.neoPosthog,
      signalrServerUrl: event.signalRServerUrl + await GetWorkflowQueryParametersUseCase().call(neoCoreSecureStorage),
      signalrMethodName: event.signalRMethodName,
      bypassSignalr: event.bypassSignalr,
    );
  }

  Future<void> _onInitWorkflow(NeoTransitionListenerEventInitWorkflow event) async {
    if (event.displayLoading) {
      onLoadingStatusChanged(displayLoading: true);
    }
    final response = await initWorkflow(
      workflowName: event.workflowName,
      queryParameters: event.queryParameters,
      isSubFlow: event.isSubFlow,
    );
    if (response.isSuccess) {
      final responseData = response.asSuccess.data;
      onLoadingStatusChanged(displayLoading: false);

      final additionalData = responseData["additionalData"] ?? {};
      if (additionalData is Map) {
        additionalData.addAll(event.initialData ?? {});
      }

      final instanceId = responseData["instanceId"];
      if (instanceId != null && instanceId is String) {
        currentWorkflowManager(isSubFlow: event.isSubFlow).setInstanceId(instanceId);
      }
      onTransitionSuccess(
        SignalrTransitionData(
          navigationPath: responseData["init-page-name"],
          navigationType:
              event.navigationType ?? NeoNavigationType.fromJson(responseData["navigation"]) ?? NeoNavigationType.push,
          pageId: responseData["state"],
          viewSource: responseData["view-source"],
          initialData: additionalData is Map ? additionalData.cast() : {"data": additionalData},
          transitionId: (responseData["transition"] as List?)?.firstOrNull["transition"] ?? "",
          queryParameters: event.queryParameters,
          useSubNavigator: event.useSubNavigator,
        ),
      );
    } else {
      onLoadingStatusChanged(displayLoading: false);
      onTransitionError?.call(response.asError.error);
    }
  }

  Future<void> _onPostTransition(NeoTransitionListenerEventPostTransition event) async {
    try {
      if (event.displayLoading) {
        onLoadingStatusChanged(displayLoading: true);
      }
      if (event.ignoreResponse) {
        unawaited(
          postTransition(
            event.transitionName,
            event.body,
            isSubFlow: event.isSubFlow,
            ignoreResponse: event.ignoreResponse,
          ),
        );
        onLoadingStatusChanged(displayLoading: false);
        return;
      }
      final transitionResponse = await postTransition(event.transitionName, event.body, isSubFlow: event.isSubFlow);
      await _retrieveTokenIfExist(transitionResponse!);
      onLoadingStatusChanged(displayLoading: false);
      await _handleTransitionResult(ongoingTransition: transitionResponse, isSubFlow: event.isSubFlow);
    } catch (e) {
      onLoadingStatusChanged(displayLoading: false);
      onTransitionError?.call(e is NeoError ? e : const NeoError());
    }
  }

  Future<void> _retrieveTokenIfExist(NeoSignalRTransition ongoingTransition) async {
    final String? token = ongoingTransition.additionalData?["access_token"];
    final String? refreshToken = ongoingTransition.additionalData?["refresh_token"];

    if (token != null && token.isNotEmpty) {
      final bool isTwoFactorAuthenticated = await neoCoreSecureStorage.setAuthToken(token);
      await neoCoreSecureStorage.write(key: NeoCoreParameterKey.secureStorageRefreshToken, value: refreshToken ?? "");
      onLoggedInSuccessfully?.call(isTwoFactorAuthenticated: isTwoFactorAuthenticated);
    }
  }

  Future<void> _handleTransitionResult({
    required NeoSignalRTransition ongoingTransition,
    required bool isSubFlow,
  }) async {
    final navigationPath = ongoingTransition.pageDetails["pageRoute"]?["label"] as String?;
    final navigationType = ongoingTransition.pageDetails["type"] as String?;
    final isBackNavigation = ongoingTransition.buttonType == "Back";
    final transitionId = ongoingTransition.transitionId;
    final isEkyc = ongoingTransition.additionalData != null && ongoingTransition.additionalData?["isEkyc"] == true;
    _handleRedirectionSettings(ongoingTransition, isSubFlow: isSubFlow);
    if (isEkyc) {
      onEkycEvent(
        EkycEventData(
          flowState: ongoingTransition.transitionId,
          ekycState: ongoingTransition.state,
          initialData: ongoingTransition.additionalData!,
        ),
      );
    } else {
      onTransitionSuccess(
        SignalrTransitionData(
          navigationPath: navigationPath,
          navigationType: NeoNavigationType.fromJson(navigationType ?? ""),
          pageId: ongoingTransition.state,
          viewSource: ongoingTransition.viewSource,
          initialData: _mergeDataWithAdditionalData(
            ongoingTransition.initialData,
            ongoingTransition.additionalData ?? {},
          ),
          isBackNavigation: isBackNavigation,
          transitionId: await getAvailableTransitionId(ongoingTransition) ?? transitionId,
          statusCode: ongoingTransition.statusCode,
          statusMessage: ongoingTransition.statusMessage,
        ),
      );
    }
  }

  void _handleRedirectionSettings(NeoSignalRTransition ongoingTransition, {required bool isSubFlow}) {
    final redirectedWorkflowId = ongoingTransition.additionalData?["amorphieWorkFlowId"];
    if (ongoingTransition.statusCode == HttpStatus.permanentRedirect.toString() && redirectedWorkflowId != null) {
      currentWorkflowManager(isSubFlow: isSubFlow).setInstanceId(redirectedWorkflowId);
    }
  }

  Map<String, dynamic> _mergeDataWithAdditionalData(Map data, Map additionalData) {
    final Map<String, dynamic> mergedMap = Map.from(data);
    additionalData.forEach((key, value) {
      if (mergedMap.containsKey(key)) {
        mergedMap[key] = _mergeValues(mergedMap[key], additionalData[key]);
      } else {
        mergedMap[key] = value;
      }
    });
    return mergedMap;
  }

  dynamic _mergeValues(dynamic value1, dynamic value2) {
    if (value1 is List && value2 is List) {
      return [...value1, ...value2];
    } else {
      return value2; // Default behavior, override value1 with value2
    }
  }
}

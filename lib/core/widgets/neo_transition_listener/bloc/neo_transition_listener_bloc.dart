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
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/analytics/neo_logger_type.dart';
import 'package:neo_core/core/analytics/neo_posthog.dart';
import 'package:neo_core/core/navigation/models/ekyc_event_data.dart';
import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/network/models/neo_signalr_event.dart';
import 'package:neo_core/core/network/neo_network.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/usecases/get_workflow_query_parameters_usecase.dart';
import 'package:neo_core/core/workflow_form/neo_sub_workflow_manager.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:rxdart/rxdart.dart';
import 'package:universal_io/io.dart';

part 'neo_transition_listener_event.dart';

part 'neo_transition_listener_state.dart';

abstract class _Constants {
  static const signalrLongPollingPeriod = Duration(seconds: 5);
  static const transitionResponseDataKey = "data";
}

class NeoTransitionListenerBloc extends Bloc<NeoTransitionListenerEvent, NeoTransitionListenerState> {
  final NeoCoreSecureStorage neoCoreSecureStorage;
  late final Function(SignalrTransitionData navigationData) onNavigationEvent;
  late final Function(EkycEventData ekycData) onEkycEvent;
  late final Function(NeoError error)? onTransitionError;
  late final Function({required bool isTwoFactorAuthenticated})? onLoggedInSuccessfully;
  late final Function({required bool displayLoading}) onLoadingStatusChanged;

  late final SignalrConnectionManager signalrConnectionManager;
  late final ReplaySubject<NeoSignalRTransition> _transitionBus = ReplaySubject(maxSize: 3);
  late final NeoWorkflowManager neoWorkflowManager;
  late final NeoLogger _neoLogger = GetIt.I.get();

  NeoSignalRTransition? _lastProcessedTransition;
  Timer? longPollingTimer;

  NeoTransitionListenerBloc({
    required this.neoCoreSecureStorage,
  }) : super(NeoTransitionListenerState()) {
    on<NeoTransitionListenerEventInit>((event, emit) => _onInit(event));
    on<NeoTransitionListenerEventInitWorkflow>(
      (event, emit) => _onInitWorkflow(event),
      transformer: droppable(),
    );
    on<NeoTransitionListenerEventPostTransition>(
      (event, emit) => _onPostTransition(event),
      transformer: droppable(),
    );
  }

  Future<void> _onInit(NeoTransitionListenerEventInit event) async {
    onNavigationEvent = event.onNavigationEvent;
    onEkycEvent = event.onEkycEvent;
    onLoggedInSuccessfully = event.onLoggedInSuccessfully;
    onTransitionError = event.onTransitionError;
    onLoadingStatusChanged = event.onLoadingStatusChanged;
    neoWorkflowManager = event.neoWorkflowManager;

    await _initSignalrConnectionManager(
      signalrServerUrl: event.signalRServerUrl + await GetWorkflowQueryParametersUseCase().call(neoCoreSecureStorage),
      signalrMethodName: event.signalRMethodName,
    );
    _transitionBus.listen((transition) {
      _lastProcessedTransition = transition;
      _processIncomingTransition(transition: transition);
    });
  }

  Future<void> _onInitWorkflow(NeoTransitionListenerEventInitWorkflow event) async {
    if (event.displayLoading) {
      onLoadingStatusChanged(displayLoading: true);
    }
    final response = await _initWorkflow(
      workflowName: event.workflowName,
      queryParameters: event.queryParameters,
      headerParameters: event.headerParameters,
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
        neoWorkflowManager.setInstanceId(instanceId);
      }
      onNavigationEvent(
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
      await neoWorkflowManager.postTransition(
        transitionName: event.transitionName,
        body: event.body,
        headerParameters: event.headerParameters,
      );
    } catch (e) {
      onLoadingStatusChanged(displayLoading: false);
      onTransitionError?.call(e is NeoError ? e : const NeoError());
    }
  }

  Future<void> _processIncomingTransition({required NeoSignalRTransition transition}) async {
    await _retrieveTokenIfExist(transition);
    onLoadingStatusChanged(displayLoading: false);

    final navigationPath = transition.pageDetails["pageRoute"]?["label"] as String?;
    final navigationType = transition.pageDetails["type"] as String?;
    final isBackNavigation = transition.buttonType == "Back";
    final transitionId = transition.transitionId;
    final isEkyc = transition.additionalData != null && transition.additionalData?["isEkyc"] == true;
    _handleRedirectionSettings(transition);
    if (isEkyc) {
      onEkycEvent(
        EkycEventData(
          flowState: transition.transitionId,
          ekycState: transition.state,
          initialData: transition.additionalData!,
        ),
      );
    } else {
      onNavigationEvent(
        SignalrTransitionData(
          navigationPath: navigationPath,
          navigationType: NeoNavigationType.fromJson(navigationType ?? ""),
          pageId: transition.state,
          viewSource: transition.viewSource,
          initialData: _mergeDataWithAdditionalData(
            transition.initialData,
            transition.additionalData ?? {},
          ),
          isBackNavigation: isBackNavigation,
          transitionId: await _getAvailableTransitionId(transition) ?? transitionId,
          statusCode: transition.statusCode,
          statusMessage: transition.statusMessage,
        ),
      );
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

  void _handleRedirectionSettings(NeoSignalRTransition ongoingTransition) {
    final redirectedWorkflowId = ongoingTransition.additionalData?["amorphieWorkFlowId"];
    if (ongoingTransition.statusCode == HttpStatus.permanentRedirect.toString() && redirectedWorkflowId != null) {
      neoWorkflowManager.setInstanceId(redirectedWorkflowId);
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

  Future<NeoResponse> _initWorkflow({
    required String workflowName,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headerParameters,
    String? instanceId,
    bool isSubFlow = false,
  }) {
    _getLastTransitionsWithLongPolling(isSubFlow: isSubFlow);

    if (instanceId == null) {
      return neoWorkflowManager.initWorkflow(
        workflowName: workflowName,
        queryParameters: queryParameters,
        headerParameters: headerParameters,
      );
    } else {
      return neoWorkflowManager.getAvailableTransitions(instanceId: instanceId);
    }
  }

  Future<String?> _getAvailableTransitionId(NeoSignalRTransition ongoingTransition) async {
    if (ongoingTransition.viewSource == "transition") {
      final response = await neoWorkflowManager.getAvailableTransitions();
      if (response.isSuccess) {
        return response.asSuccess.data["transition"]?.first["transition"];
      }
    }
    return null;
  }

  Future<void> _initSignalrConnectionManager({
    required String signalrServerUrl,
    required String signalrMethodName,
  }) async {
    signalrConnectionManager = SignalrConnectionManager(
      serverUrl: signalrServerUrl,
      methodName: signalrMethodName,
    );
    await signalrConnectionManager.init();
    signalrConnectionManager.listenForTransitionEvents(
      onEvent: (NeoSignalREvent event) async {
        if (_lastProcessedTransition == null || event.transition.time.isAfter(_lastProcessedTransition!.time)) {
          _transitionBus.add(event.transition);
        }
      },
    );
  }

  void _getLastTransitionsWithLongPolling({
    required bool isSubFlow,
  }) {
    longPollingTimer?.cancel();
    longPollingTimer = Timer.periodic(
      _Constants.signalrLongPollingPeriod,
      (timer) async {
        final response = await neoWorkflowManager.getLastTransitionByLongPolling();
        if (response.isSuccess) {
          final responseData = response.asSuccess.data;
          final event = NeoSignalREvent.fromJson(responseData);
          final events = event.previousEvents
            ..add(event)
            ..sort((a, b) => a.transition.time.compareTo(b.transition.time));

          for (final event in events) {
            if (_lastProcessedTransition == null || event.transition.time.isAfter(_lastProcessedTransition!.time)) {
              _transitionBus.add(event.transition);
            }
          }
        } else {
          _neoLogger.logCustom(
            "[NeoTransitionListener]: Retrieving last event by long polling is failed!",
            logTypes: [NeoLoggerType.posthog],
          );
        }
      },
    );
  }

  @override
  Future<void> close() {
    signalrConnectionManager.stop();
    _transitionBus.close();
    return super.close();
  }
}

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
import 'package:neo_core/core/bus/neo_bus.dart';
import 'package:neo_core/core/navigation/models/ekyc_event_data.dart';
import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/network/models/neo_signalr_event.dart';
import 'package:neo_core/core/network/models/neo_signalr_transition_state_type.dart';
import 'package:neo_core/core/network/neo_network.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/widgets/neo_page/bloc/neo_page_bloc.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/usecases/get_workflow_query_parameters_usecase.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:rxdart/rxdart.dart';
import 'package:universal_io/io.dart';

part 'neo_transition_listener_event.dart';

part 'neo_transition_listener_state.dart';

abstract class _Constants {
  static const signalrLongPollingPeriod = Duration(seconds: 5);
  static const transitionTimeoutDuration = Duration(seconds: 60);
}

class NeoTransitionListenerBloc extends Bloc<NeoTransitionListenerEvent, NeoTransitionListenerState> {
  final NeoCoreSecureStorage neoCoreSecureStorage;
  late final Function(SignalrTransitionData navigationData) onTransitionEvent;
  late final Function(EkycEventData ekycData) onEkycEvent;
  late final Function(NeoError error)? onTransitionError;
  late final Function({required bool isTwoFactorAuthenticated})? onLoggedInSuccessfully;
  late final Function({required bool displayLoading}) onLoadingStatusChanged;

  late final SignalrConnectionManager signalrConnectionManager;
  late final ReplaySubject<NeoSignalREvent> _eventBus = ReplaySubject(maxSize: 5);
  late final NeoWorkflowManager neoWorkflowManager;
  late final NeoLogger _neoLogger = GetIt.I.get();

  Completer? _postTransitionTimeoutCompleter;
  Timer? _postTransitionTimeoutTimer;
  NeoSignalREvent? _lastProcessedEvent;
  Timer? longPollingTimer;
  bool hasSignalRConnection = false;

  NeoTransitionListenerBloc({
    required this.neoCoreSecureStorage,
  }) : super(const NeoTransitionListenerState(temporarilyDisabled: false)) {
    on<NeoTransitionListenerEventInit>(_onInit);
    on<NeoTransitionListenerEventInitWorkflow>(
      (event, emit) => _onInitWorkflow(event),
      transformer: droppable(),
    );
    on<NeoTransitionListenerEventPostTransition>(
      (event, emit) => _onPostTransition(event),
      transformer: droppable(),
    );
    on<NeoTransitionListenerEventDisableTemporarily>(
      (event, emit) => emit(state.copyWith(temporarilyDisabled: event.temporarilyDisabled)),
    );
    on<NeoTransitionListenerEventStopListening>((event, emit) => _onStopListening());
  }

  Future<void> _onInit(NeoTransitionListenerEventInit event, emit) async {
    onTransitionEvent = event.onTransitionEvent;
    onEkycEvent = event.onEkycEvent;
    onLoggedInSuccessfully = event.onLoggedInSuccessfully;
    onTransitionError = event.onTransitionError;
    onLoadingStatusChanged = event.onLoadingStatusChanged;
    neoWorkflowManager = event.neoWorkflowManager;

    await _initSignalrConnectionManager(
      signalrServerUrl: event.signalRServerUrl + await GetWorkflowQueryParametersUseCase().call(neoCoreSecureStorage),
      signalrMethodName: event.signalRMethodName,
    );
    _listenEventBus(emit);
  }

  void _listenEventBus(emit) {
    _eventBus.listen((event) {
      if (isClosed ||
          _eventBus.isClosed ||
          event.transition.instanceId.isEmpty ||
          event.transition.instanceId != neoWorkflowManager.instanceId) {
        return;
      }
      if (state.temporarilyDisabled) {
        add(NeoTransitionListenerEventDisableTemporarily(temporarilyDisabled: false));
        return;
      }

      if (_lastProcessedEvent?.transition == null ||
          !event.transition.time.isBefore(_lastProcessedEvent!.transition.time)) {
        if (_postTransitionTimeoutCompleter != null && !_postTransitionTimeoutCompleter!.isCompleted) {
          _postTransitionTimeoutTimer?.cancel();
          _postTransitionTimeoutCompleter?.complete();
        }
        if (event.transition.workflowStateType.isTerminated) {
          _onStopListening();
        }
        if (event.isSilentEvent) {
          GetIt.I.get<NeoWidgetEventBus>().addEvent(
                NeoWidgetEvent(eventId: NeoPageBloc.dataEventKey, data: event.transition),
              );
        } else {
          _processIncomingTransition(transition: event.transition);
        }
        _lastProcessedEvent = event;
      }
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
        neoWorkflowManager.setInstanceId(instanceId, isSubFlow: event.isSubFlow);
      }
      onTransitionEvent(
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
          isInitialPage: true,
        ),
      );
    } else {
      _completeWithError(response.asError.error);
    }
  }

  Future<void> _onPostTransition(NeoTransitionListenerEventPostTransition event) async {
    _initPostTransitionTimeoutCompleter();
    _getLastTransitionsWithLongPolling(isSubFlow: event.isSubFlow);

    try {
      if (event.displayLoading) {
        onLoadingStatusChanged(displayLoading: true);
      }
      await neoWorkflowManager.postTransition(
        transitionName: event.transitionName,
        body: event.body,
        headerParameters: event.headerParameters,
        isSubFlow: event.isSubFlow,
      );
    } catch (e) {
      _completeWithError(e is NeoError ? e : const NeoError());
    }
  }

  void _onStopListening() {
    _cancelLongPolling();
    neoWorkflowManager.terminateWorkflow();
  }

  void _initPostTransitionTimeoutCompleter() {
    _postTransitionTimeoutCompleter = Completer();
    _postTransitionTimeoutTimer?.cancel();

    _postTransitionTimeoutTimer = Timer(_Constants.transitionTimeoutDuration, () {
      if (_postTransitionTimeoutCompleter != null && !_postTransitionTimeoutCompleter!.isCompleted) {
        _completeWithError(const NeoError());
        _postTransitionTimeoutCompleter!.complete();
      }
    });
  }

  void _completeWithError(NeoError error) {
    onLoadingStatusChanged(displayLoading: false);
    onTransitionError?.call(error);
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
      final transitionData = SignalrTransitionData(
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
      );
      onTransitionEvent(transitionData);
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
        isSubFlow: isSubFlow,
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
    await signalrConnectionManager.init(_onSignalRConnectionStatusChanged);
    signalrConnectionManager.listenForSignalREvents(onEvent: _addEventToBus);
  }

  void _addEventToBus(NeoSignalREvent event) {
    if (!_eventBus.values.contains(event)) {
      if (!isClosed && !_eventBus.isClosed && _lastProcessedEvent?.eventId != event.eventId) {
        _eventBus.add(event);
      }
    }
  }

  void _onSignalRConnectionStatusChanged({required bool hasConnection}) {
    hasSignalRConnection = hasConnection;
    if (hasConnection) {
      _cancelLongPolling();
    } else {
      _getLastTransitionsWithLongPolling(isSubFlow: false);
    }
  }

  void _getLastTransitionsWithLongPolling({
    required bool isSubFlow,
  }) {
    _cancelLongPolling();
    if (hasSignalRConnection || isClosed) {
      return;
    }

    longPollingTimer = Timer.periodic(
      _Constants.signalrLongPollingPeriod,
      (timer) async {
        final response = await neoWorkflowManager.getLastTransitionByLongPolling(isSubFlow: isSubFlow);
        if (response.isSuccess) {
          final responseData = response.asSuccess.data;
          final event = NeoSignalREvent.fromJson(responseData);
          final events = List.from(event.previousEvents)
            ..add(event)
            ..sort((a, b) => a.transition.time.compareTo(b.transition.time));

          for (final event in events) {
            _addEventToBus(event);
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

  void _cancelLongPolling() {
    _postTransitionTimeoutTimer?.cancel();
    longPollingTimer?.cancel();
  }

  @override
  Future<void> close() {
    _postTransitionTimeoutTimer?.cancel();
    signalrConnectionManager.stop();
    _cancelLongPolling();
    _eventBus.close();
    return super.close();
  }
}

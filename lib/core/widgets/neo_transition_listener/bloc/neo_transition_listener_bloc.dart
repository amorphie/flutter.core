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
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mutex/mutex.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/analytics/neo_logger_type.dart';
import 'package:neo_core/core/bus/neo_bus.dart';
import 'package:neo_core/core/navigation/models/ekyc_event_data.dart';
import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/network/helpers/mtls_helper.dart';
import 'package:neo_core/core/network/models/http_auth_response.dart';
import 'package:neo_core/core/network/models/neo_signalr_event.dart';
import 'package:neo_core/core/network/models/neo_signalr_transition_state_type.dart';
import 'package:neo_core/core/network/neo_network.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/widgets/neo_page/bloc/neo_page_bloc.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/bloc/usecases/process_login_certificate_silent_event_use_case.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/usecases/get_workflow_query_parameters_usecase.dart';
import 'package:neo_core/core/workflow_form/neo_vnext_workflow_manager.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:universal_io/io.dart';

part 'neo_transition_listener_event.dart';
part 'neo_transition_listener_state.dart';

abstract class _Constants {
  static const transitionTimeoutDuration = Duration(seconds: 60);
}

class NeoTransitionListenerBloc extends Bloc<NeoTransitionListenerEvent, NeoTransitionListenerState>
    with WidgetsBindingObserver {
  final NeoCoreSecureStorage neoCoreSecureStorage;
  late final Function(SignalrTransitionData navigationData) onTransitionEvent;
  late final Function(NeoSignalRTransition data) onSilentEvent;
  late final Function(EkycEventData ekycData) onEkycEvent;
  late final Function(NeoError error, {required bool displayAsPopup})? onTransitionError;
  late final Future Function({required bool isTwoFactorAuthenticated})? onLoggedInSuccessfully;
  late final Function({required bool displayLoading}) onLoadingStatusChanged;

  late final SignalrConnectionManager signalrConnectionManager;
  late final List<NeoSignalREvent> _eventList = [];
  late final NeoWorkflowManager neoWorkflowManager;
  late final NeoVNextWorkflowManager neoVNextWorkflowManager;
  late final NeoLogger _neoLogger = GetIt.I.get();
  late String signalRServerUrl;
  late final String signalRMethodName;
  late final Duration signalrLongPollingPeriod;
  late final Duration signalRTimeoutDuration;

  Completer? _postTransitionTimeoutCompleter;
  Timer? _postTransitionTimeoutTimer;
  NeoSignalREvent? _lastProcessedEvent;
  Timer? longPollingTimer;
  bool hasSignalRConnection = false;
  final Mutex _eventProcessorMutex = Mutex();

  NeoTransitionListenerBloc({required this.neoCoreSecureStorage}) : super(const NeoTransitionListenerState()) {
    WidgetsBinding.instance.addObserver(this);

    on<NeoTransitionListenerEventInit>(_onInit);
    on<NeoTransitionListenerEventInitWorkflow>(
      (event, emit) => _onInitWorkflow(event),
      transformer: droppable(),
    );
    on<NeoTransitionListenerEventPostTransition>(
      (event, emit) => _onPostTransition(event),
      transformer: droppable(),
    );
    on<NeoTransitionListenerEventUpdateSignalrServerUrl>(_onUpdateSignalrServerUrl);
    on<NeoTransitionListenerEventStopListening>((event, emit) => _onStopListening());
  }

  Future<void> _onInit(NeoTransitionListenerEventInit event, emit) async {
    onTransitionEvent = event.onTransitionEvent;
    onSilentEvent = event.onSilentEvent;
    onEkycEvent = event.onEkycEvent;
    onLoggedInSuccessfully = event.onLoggedInSuccessfully;
    onTransitionError = event.onTransitionError;
    onLoadingStatusChanged = event.onLoadingStatusChanged;
    neoWorkflowManager = event.neoWorkflowManager;
    neoVNextWorkflowManager = event.neoVNextWorkflowManager;
    signalRServerUrl = event.signalRServerUrl;
    signalRMethodName = event.signalRMethodName;
    signalrConnectionManager = SignalrConnectionManager();
    signalrLongPollingPeriod = event.signalrLongPollingPeriod;
    signalRTimeoutDuration = event.signalRTimeoutDuration;

    await _initSignalrConnectionManager();
  }

  Future<void> _processEvents({bool fromSignalR = false}) async {
    if (_eventList.isNotEmpty) {
      await _eventProcessorMutex.protect(() async {
        _eventList.sortBy((element) => element.transition.time);
        final List<NeoSignalREvent> processedEvents = [];

        for (final event in List<NeoSignalREvent>.from(_eventList)) {
          if (isClosed ||
              event.transition.instanceId.isEmpty ||
              !(event.transition.instanceId == neoWorkflowManager.instanceId ||
                  event.transition.instanceId == neoWorkflowManager.subFlowInstanceId)) {
            processedEvents.add(event);
            continue;
          }

          if (_lastProcessedEvent?.transition == null ||
              !event.transition.time.isBefore(_lastProcessedEvent!.transition.time)) {
            if (fromSignalR) {
              _cancelLongPolling();
            }

            if (_postTransitionTimeoutCompleter != null && !_postTransitionTimeoutCompleter!.isCompleted) {
              _postTransitionTimeoutTimer?.cancel();
              _postTransitionTimeoutCompleter?.complete();
            }

            if (event.transition.workflowStateType.isTerminated) {
              _onStopListening();
            }
            if (event.isSilentEvent) {
              unawaited(ProcessLoginCertificateSilentEventUseCase().call(event, this, neoCoreSecureStorage));
              GetIt.I.get<NeoWidgetEventBus>().addEvent(
                    NeoWidgetEvent(eventId: NeoPageBloc.dataEventKey, data: event.transition),
                  );
              onSilentEvent(event.transition);
            } else {
              await _processIncomingTransition(transition: event.transition);
            }
            _lastProcessedEvent = event;
          }
          processedEvents.add(event);
        }

        for (final event in processedEvents) {
          _eventList.remove(event);
        }
      });

      await _processEvents();
    }
  }

  Future<void> _onInitWorkflow(NeoTransitionListenerEventInitWorkflow event) async {
    if (event.displayLoading) {
      onLoadingStatusChanged(displayLoading: true);
    }
    final response = await _initWorkflow(
      workflowName: event.workflowName,
      workflowDomain: event.workflowDomain,
      workflowVersion: event.workflowVersion,
      queryParameters: event.queryParameters,
      headerParameters: event.headerParameters,
      isSubFlow: event.isSubFlow,
    );
    if (response.isSuccess) {
      final responseData = response.asSuccess.data;
      if (event.displayLoading) {
        onLoadingStatusChanged(displayLoading: false);
      }

      final additionalData = responseData["additionalData"] ?? {};
      if (additionalData is Map) {
        additionalData.addAll(event.initialData ?? {});
      }

      final instanceId = responseData["instanceId"];
      if (instanceId != null && instanceId is String) {
        neoWorkflowManager.setInstanceId(instanceId, isSubFlow: event.isSubFlow);
      }

      if (event.isVNextEvent) {
        await neoVNextWorkflowManager.startPolling(
          workflowName: event.workflowName,
          workflowDomain: event.workflowDomain ?? "",
          instanceId: responseData["id"],
        );
      } else {
        onTransitionEvent(
          SignalrTransitionData(
            navigationPath: responseData["init-page-name"],
            navigationType: event.navigationType ??
                NeoNavigationType.fromJson(responseData["navigation"]) ??
                NeoNavigationType.push,
            pageId: responseData["state"],
            viewSource: responseData["view-source"],
            initialData: additionalData is Map ? additionalData.cast() : {"data": additionalData},
            transitionId: (responseData["transition"] as List?)?.firstOrNull?["transition"] ?? "",
            queryParameters: event.queryParameters,
            useSubNavigator: event.useSubNavigator,
            useRootNavigator: event.useRootNavigator,
            isInitialPage: true,
          ),
        );
      }
    } else {
      _completeWithError(response.asError.error, shouldHideLoading: event.displayLoading, displayAsPopup: true);
    }
  }

  Future<void> _onPostTransition(NeoTransitionListenerEventPostTransition event) async {
    _initPostTransitionTimeoutCompleter(displayLoading: event.displayLoading);
    try {
      if (event.resetInstanceId) {
        neoWorkflowManager.resetInstanceId(isSubFlow: event.isSubFlow);
      }
      if (event.workflowName != null && event.workflowName!.isNotEmpty) {
        neoWorkflowManager.setWorkflowName(event.workflowName!, isSubFlow: event.isSubFlow);
      }
      if (event.displayLoading) {
        onLoadingStatusChanged(displayLoading: true);
      }
      final response = await neoWorkflowManager.postTransition(
        transitionName: event.transitionName,
        body: event.body,
        headerParameters: event.headerParameters,
        isSubFlow: event.isSubFlow,
      );
      if (response.isError) {
        _completeWithError(response.asError.error, shouldHideLoading: event.displayLoading);
      } else {
        unawaited(_initSignalrConnectionManager());
      }
      _getLastTransitionsWithLongPolling(isSubFlow: event.isSubFlow);
    } catch (e) {
      _completeWithError(e is NeoError ? e : const NeoError(), shouldHideLoading: event.displayLoading);
    }
  }

  Future<void> _onUpdateSignalrServerUrl(event, emit) async {
    signalRServerUrl = event.serverUrl;
  }

  void _onStopListening() {
    _cancelLongPolling();
    neoWorkflowManager.terminateWorkflow();
  }

  void _initPostTransitionTimeoutCompleter({required bool displayLoading}) {
    _postTransitionTimeoutCompleter = Completer();
    _postTransitionTimeoutTimer?.cancel();

    _postTransitionTimeoutTimer = Timer(_Constants.transitionTimeoutDuration, () {
      final isTransitionCompleted = _postTransitionTimeoutCompleter?.isCompleted ?? false;
      if (!isTransitionCompleted) {
        _completeWithError(const NeoError(), shouldHideLoading: displayLoading);
        _postTransitionTimeoutCompleter!.complete();
      }
    });
  }

  void _completeWithError(NeoError error, {required bool shouldHideLoading, bool displayAsPopup = false}) {
    if (shouldHideLoading) {
      onLoadingStatusChanged(displayLoading: false);
    }
    onTransitionError?.call(error, displayAsPopup: displayAsPopup);
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
        isInitialPage: transition.workflowStateType == NeoSignalRTransitionStateType.start,
        useRootNavigator: transition.initialData["useRootNavigator"] == true,
      );
      onTransitionEvent(transitionData);
    }
  }

  Future<void> _retrieveTokenIfExist(NeoSignalRTransition ongoingTransition) async {
    final String? token = ongoingTransition.additionalData?["access_token"];
    final String? refreshToken = ongoingTransition.additionalData?["refresh_token"];
    final int expiresIn = ongoingTransition.additionalData?["expires_in"] ?? 0;
    final int refreshTokenExpiresIn = ongoingTransition.additionalData?["refresh_token_expires_in"] ?? 0;
    final bool? isMobUnapproved = ongoingTransition.additionalData?["user_info"]?['is_mob_unapproved_caused_by_ekyc'];

    if (token != null && token.isNotEmpty) {
      final isTwoFactorAuthenticated = await neoWorkflowManager.neoNetworkManager.setTokensByAuthResponse(
        HttpAuthResponse(
          token: token,
          refreshToken: refreshToken ?? "",
          expiresInSeconds: expiresIn,
          refreshTokenExpiresInSeconds: refreshTokenExpiresIn,
        ),
        isMobUnapproved: isMobUnapproved,
      );
      await _retrieveClientCertificateIfExist(ongoingTransition.additionalData?["clientCert"]);
      await onLoggedInSuccessfully?.call(isTwoFactorAuthenticated: isTwoFactorAuthenticated);
    }
  }

  Future<void> _retrieveClientCertificateIfExist(Map? data) async {
    if (kIsWeb) {
      return;
    }
    final String? privateKey = data?["privateKey"];
    final String? certificate = data?["certificate"];

    if (privateKey != null && certificate != null) {
      final result = await Future.wait([
        neoCoreSecureStorage.read(NeoCoreParameterKey.secureStorageCustomerId),
        neoCoreSecureStorage.read(NeoCoreParameterKey.secureStorageDeviceId),
      ]);

      final userReference = result[0];
      final deviceId = result[1];

      await MtlsHelper().storePrivateKeyWithCertificate(
        clientKeyTag: "$deviceId$userReference",
        privateKey: privateKey,
        certificate: certificate,
      );
    }
    await neoWorkflowManager.neoNetworkManager.updateSecurityContext();
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
    String? workflowDomain,
    String? workflowVersion,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headerParameters,
    String? instanceId,
    bool isSubFlow = false,
  }) async {
    if (await _isVNextWorkflow(workflowName)) {
      return neoVNextWorkflowManager.startWorkflow(
        workflowName: workflowName,
        workflowDomain: workflowDomain ?? "",
        version: workflowVersion ?? "",
      );
    } else if (instanceId == null) {
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

  Future<bool> _isVNextWorkflow(String workflowName) async {
    // TODO STOPSHIP: Get it from config
    final vNextWorkflowNames = [
      "account-opening",
    ];
    return vNextWorkflowNames.contains(workflowName);
  }

  Future<String?> _getAvailableTransitionId(NeoSignalRTransition ongoingTransition) async {
    if (ongoingTransition.viewSource == "transition") {
      final response = await neoWorkflowManager.getAvailableTransitions();
      if (response.isSuccess) {
        return response.asSuccess.data["transition"]?.firstOrNull?["transition"];
      }
    }
    return null;
  }

  Future<void> _initSignalrConnectionManager() async {
    if (hasSignalRConnection || neoWorkflowManager.neoNetworkManager.isTokenExpired) {
      return;
    }
    await signalrConnectionManager.init(
      serverUrl: signalRServerUrl + await GetWorkflowQueryParametersUseCase().call(neoCoreSecureStorage),
      methodName: signalRMethodName,
      onConnectionStatusChanged: _onSignalRConnectionStatusChanged,
    );
    signalrConnectionManager.listenForSignalREvents(onEvent: (event) => _addEventToBus(event, fromSignalR: true));
  }

  void _addEventToBus(NeoSignalREvent event, {required bool fromSignalR}) {
    if (!_eventList
        .any((element) => element.eventId == event.eventId || element.transition.time.isAfter(event.transition.time))) {
      if (!isClosed && _lastProcessedEvent?.eventId != event.eventId) {
        _eventList.add(event);
      }
      _processEvents(fromSignalR: fromSignalR);
    }
  }

  void _onSignalRConnectionStatusChanged({required bool hasConnection}) {
    hasSignalRConnection = hasConnection;
    if (hasConnection) {
      _cancelLongPolling();
      _getLastTransitionsWithLongPolling(isSubFlow: false, onlyOnce: true);
    } else {
      _getLastTransitionsWithLongPolling(isSubFlow: false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _cancelLongPolling();
    } else if (state == AppLifecycleState.resumed) {
      _getLastTransitionsWithLongPolling(isSubFlow: false);
    }
  }

  void _getLastTransitionsWithLongPolling({
    required bool isSubFlow,
    bool onlyOnce = false,
  }) {
    _cancelLongPolling();
    if (!onlyOnce && (hasSignalRConnection || isClosed || !neoWorkflowManager.hasActiveWorkflow)) {
      return;
    }

    timerCallback([_]) async {
      final response = await neoWorkflowManager.getLastTransitionByLongPolling(isSubFlow: isSubFlow);
      if (response.isSuccess) {
        final responseData = response.asSuccess.data;
        final event = NeoSignalREvent.fromJson(responseData);
        final events = List.from(event.previousEvents)
          ..add(event)
          ..sort((a, b) => a.transition.time.compareTo(b.transition.time));

        for (final event in events) {
          _addEventToBus(event, fromSignalR: false);
        }
      } else {
        if (response.asError.error.responseCode == HttpStatus.notFound) {
          _cancelLongPolling();
        }
        _neoLogger.logCustom(
          "[NeoTransitionListener]: Retrieving last event by long polling is failed!",
          logTypes: [NeoLoggerType.elastic],
        );
      }
    }

    timerCallback();
    if (!onlyOnce) {
      longPollingTimer = Timer.periodic(signalrLongPollingPeriod, timerCallback);
    }
  }

  void _cancelLongPolling() {
    _postTransitionTimeoutTimer?.cancel();
    longPollingTimer?.cancel();
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _postTransitionTimeoutTimer?.cancel();
    signalrConnectionManager.stop();
    _cancelLongPolling();
    return super.close();
  }
}

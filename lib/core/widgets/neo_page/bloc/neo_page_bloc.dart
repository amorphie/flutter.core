import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_widget_event.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_widget_event_bus.dart';
import 'package:neo_core/core/network/models/neo_signalr_transition.dart';

part 'neo_page_event.dart';

part 'neo_page_state.dart';

abstract class _Constants {
  static const String keyItemIdentifier = "itemIdentifierKey";
}

class NeoPageBloc extends Bloc<NeoPageEvent, NeoPageState> {
  static const dataEventKey = "NeoPageBlocDataEventKey";

  final JsonWidgetRegistry jsonWidgetRegistry;
  final String pageId;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formInitialData;
  final Map<String, dynamic> _formData;
  FocusNode? _failureFocusNode;

  final List<StreamSubscription> _subscriptionList = [];

  void addToDisposeList(StreamSubscription subscription) {
    _subscriptionList.add(subscription);
  }

  bool isStateChanged() => !const DeepCollectionEquality.unordered().equals(_formInitialData, _formData);

  Map<String, dynamic> get formData => _formData;

  NeoPageBloc({required this.pageId, required this.jsonWidgetRegistry, Map<String, dynamic>? initialPageData})
      : _formInitialData = Map.from(initialPageData ?? {}),
        _formData = Map.from(initialPageData ?? {}),
        super(const NeoPageState()) {
    _listenWidgetEvents();

    on<NeoPageEventResetForm>((event, emit) {
      formKey.currentState?.reset();
      clearFailureFocusNode();
    });
    on<NeoPageEventAddInitialParameters>((event, emit) {
      _formInitialData.addAll(event.parameters);
      _formData.addAll(event.parameters);
    });
    on<NeoPageEventAddAllParameters>((event, emit) => addAllParameters(event));
    on<NeoPageEventAddParametersIntoArray>((event, emit) => addParametersIntoArray(event));
  }

  void addAllParameters(NeoPageEventAddAllParameters event) {
    _formData.addAll(event.parameters);
  }

  void removeParameter(String key) {
    _formData.remove(key);
    _formInitialData.remove(key);
  }

  void addParametersIntoArray(NeoPageEventAddParametersIntoArray event) {
    final newValue = event.value;
    newValue[_Constants.keyItemIdentifier] = event.itemIdentifierKey;

    final List<Map> currentItemList = List<Map>.from(_formData[event.sharedDataKey] ?? []);
    final index = currentItemList
        .indexWhere((currentItem) => currentItem[_Constants.keyItemIdentifier] == event.itemIdentifierKey);

    if (index != -1) {
      if (!const DeepCollectionEquality.unordered().equals(currentItemList[index], newValue)) {
        currentItemList[index] = newValue;
      }
    } else {
      currentItemList.add(event.value);
    }

    _formData[event.sharedDataKey] = currentItemList;

    if (event.isInitialValue) {
      _formInitialData[event.sharedDataKey] = currentItemList;
    }
  }

  Map<String, dynamic> getChangedFormData() {
    final Map<String, dynamic> stateDifference = {};

    for (final entry in formData.entries) {
      final key = entry.key;
      final value = entry.value;

      final initialData = _formInitialData[key];

      if (_formInitialData.containsKey(key)) {
        if (value is List) {
          if (const DeepCollectionEquality.unordered().equals(value, initialData)) {
            continue;
          }

          final List<dynamic> initialList = initialData ?? [];
          final List<dynamic> updatedList = value;

          final List<dynamic> diffList = updatedList.where((item) => !initialList.contains(item)).toList();

          if (diffList.isNotEmpty) {
            stateDifference[key] = diffList;
          }
        } else if (initialData != value) {
          stateDifference[key] = value;
        }
      } else {
        if (initialData != value) {
          stateDifference[key] = value;
        }
      }
    }

    return stateDifference;
  }

  bool validateForm() {
    clearFailureFocusNode();
    final isValid = formKey.currentState?.validate();
    if (isValid != true && _failureFocusNode != null) {
      _failureFocusNode!.requestFocus();
      final failureContext = _failureFocusNode!.context;
      if (failureContext != null) {
        Scrollable.ensureVisible(failureContext, alignment: 0.2);
      }
    }
    return isValid ?? false;
  }

  FocusNode? get failureFocusNode => _failureFocusNode;

  set failureFocusNode(FocusNode? focusNode) {
    _failureFocusNode ??= focusNode;
  }

  void clearFailureFocusNode() {
    _failureFocusNode = null;
  }

  void _listenWidgetEvents() {
    addToDisposeList(
      GetIt.I.get<NeoWidgetEventBus>().listen(
            eventId: dataEventKey,
            onEventReceived: (NeoWidgetEvent event) {
              final transition = event.data! as NeoSignalRTransition;
              if (transition.dataPageId == pageId) {
                addAllParameters(NeoPageEventAddAllParameters(transition.additionalData ?? {}));
              }
            },
          ),
    );
  }

  @override
  Future<void> close() {
    for (final subscription in _subscriptionList) {
      subscription.cancel();
    }
    return super.close();
  }
}

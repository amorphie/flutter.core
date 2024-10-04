import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

part 'neo_page_event.dart';
part 'neo_page_state.dart';

abstract class _Constants {
  static const String keyItemIdentifier = "itemIdentifierKey";
}

class NeoPageBloc extends Bloc<NeoPageEvent, NeoPageState> {
  final JsonWidgetRegistry jsonWidgetRegistry;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formInitialData;
  final Map<String, dynamic> _formData;
  final Map<String, FocusNode> _failureFocusNodeMap = {};
  final Map<String, bool> _isCustomFieldsValidMap = {};

  final List<StreamSubscription> _subscriptionList = [];

  void addToDisposeList(StreamSubscription subscription) {
    _subscriptionList.add(subscription);
  }

  bool isStateChanged() => !const DeepCollectionEquality.unordered().equals(_formInitialData, _formData);

  Map<String, dynamic> get formData => _formData;

  NeoPageBloc({required this.jsonWidgetRegistry, Map<String, dynamic>? initialPageData})
      : _formInitialData = Map.from(initialPageData ?? {}),
        _formData = Map.from(initialPageData ?? {}),
        super(const NeoPageState()) {
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
    bool shouldClear = true;
    for (final entry in _isCustomFieldsValidMap.entries) {
      if (!entry.value && _failureFocusNodeMap.containsKey(entry.key)) {
        shouldClear = false;
        break;
      }
    }

    if (shouldClear) {
      clearFailureFocusNode();
    }

    final isValid = formKey.currentState?.validate();
    final bool isCustomFieldValid =
        _isCustomFieldsValidMap.isEmpty || _isCustomFieldsValidMap.values.every((element) => element);
    FocusNode? failureFocus;
    if ((isValid != true || !isCustomFieldValid) && _failureFocusNodeMap.isNotEmpty) {
      final String? failureKey =
          !isCustomFieldValid ? _isCustomFieldsValidMap.entries.firstWhere((entry) => !entry.value).key : null;

      if (failureKey != null) {
        failureFocus = _failureFocusNodeMap[failureKey];
      } else {
        // Remove all FocusNodes whose key matches any key in _isCustomFieldsValidMap
        _failureFocusNodeMap.removeWhere((key, focusNode) => _isCustomFieldsValidMap.containsKey(key));
        // Assign the first FocusNode from the remaining map to failureFocus
        if (_failureFocusNodeMap.isNotEmpty) {
          failureFocus = _failureFocusNodeMap.values.first;
        }
      }

      failureFocus?.requestFocus();

      final failureContext = failureFocus?.context;
      if (failureContext != null) {
        Scrollable.ensureVisible(failureContext, alignment: 0.2);
      }
    }
    return isValid != null && isValid && isCustomFieldValid;
  }

  List<FocusNode> get failureFocusNode => _failureFocusNodeMap.values.toList();
  Map<String, bool> get isCustomFieldsValidMap => _isCustomFieldsValidMap;

  void addFailureFocusNode(Map<String, FocusNode> focusMap) {
    _failureFocusNodeMap.addAll(focusMap);
  }

  void addToIsCustomFieldsValidMap(Map<String, bool> isValidMap) {
    _isCustomFieldsValidMap.addAll(isValidMap);
  }

  void clearFailureFocusNode({String? key}) {
    if (key != null) {
      _failureFocusNodeMap.remove(key);
    } else {
      _failureFocusNodeMap.clear();
    }
  }

  @override
  Future<void> close() {
    for (final subscription in _subscriptionList) {
      subscription.cancel();
    }
    return super.close();
  }
}

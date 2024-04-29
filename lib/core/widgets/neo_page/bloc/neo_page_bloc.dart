import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'neo_page_event.dart';
part 'neo_page_state.dart';

abstract class _Constants {
  static const String keyItemIdentifier = "itemIdentifierKey";
}

class NeoPageBloc extends Bloc<NeoPageEvent, NeoPageState> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formInitialData = {};
  final Map<String, dynamic> _formData = {};

  bool isStateChanged() => !const DeepCollectionEquality.unordered().equals(_formInitialData, _formData);

  Map<String, dynamic> get formData => _formData;

  NeoPageBloc() : super(const NeoPageState()) {
    on<NeoPageEventResetForm>((event, emit) {
      formKey.currentState?.reset();
    });
    on<NeoPageEventAddInitialParameters>((event, emit) {
      _formInitialData.addAll(event.parameters);
      _formData.addAll(event.parameters);
    });
    on<NeoPageEventAddAllParameters>((event, emit) {
      _formData.addAll(event.parameters);
    });
    on<NeoPageEventAddParametersIntoArray>(_onAddParametersIntoArray);
    on<NeoPageEventValidateForm>((event, emit) => formKey.currentState?.validate());
    on<NeoPageEventAddParametersWithPath>(_onNeoPageEventAddParametersWithPath);
  }

  void _onAddParametersIntoArray(NeoPageEventAddParametersIntoArray event, Emitter<NeoPageState> emit) {
    final newValue = event.value;
    newValue[_Constants.keyItemIdentifier] = event.itemIdentifierKey;

    final List<Map> currentItemList = List<Map>.from(_formData[event.sharedDataKey] ?? []);
    final hasValue = currentItemList.isNotEmpty && currentItemList.any((element) => element[_Constants.keyItemIdentifier] == event.itemIdentifierKey);

    if (hasValue) {
      currentItemList.removeWhere((currentItem) => currentItem[_Constants.keyItemIdentifier] == event.itemIdentifierKey);
      final index = currentItemList.indexWhere((currentItem) => currentItem[_Constants.keyItemIdentifier] == event.itemIdentifierKey);

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

  void _onNeoPageEventAddParametersWithPath(NeoPageEventAddParametersWithPath event, Emitter<NeoPageState> emit) {
    final RegExp exp = RegExp(r"(\w+|\[.*?\])");
    final Iterable<Match> matches = exp.allMatches(event.dataPath);
    final List<dynamic> path = [];

    for (final Match match in matches) {
      if (match.group(1) != null) {
        path.add(match.group(1) ?? "");
      } else if (match.group(0) != '\$') {
        path.add(match.group(0));
      }
    }

    _formData.addAll(setNestedMapValue(_formData, path, event.value));
    debugPrint("${event.dataPath}\n$_formData");
  }
}

dynamic setNestedMapValue(dynamic map, List<dynamic> path, dynamic value, [int i = 0]) {
  dynamic current = map;
  final String currentPath = path[i];

  final bool isList = currentPath.startsWith("[") && currentPath.endsWith("]");
  // var index = list.indexWhere((item) => item['_id'] == id);
  final bool isEmpty = (isList && (current == null || current.isEmpty)) || (!isList && (current[currentPath] == null || current[currentPath].isEmpty));
  final bool isLast = i == path.length - 1;
  if (isEmpty) {
    if (isList) {
      current = [];
    } else {
      current[currentPath] = {};
    }
  }

  if (isLast) {
    if (current is List) {
      final String? id = isList ? currentPath.substring(1, currentPath.length - 1) : null;
      final int index = current.indexWhere((item) => item['_id'] == id);
      if (index > -1) {
        current[index].addAll(value);
      } else {
        value['_id'] = id;
        current.add(value);
      }
    } else {
      current[currentPath].addAll(value);
    }
  } else {
    current[currentPath] = setNestedMapValue(current[currentPath], path, value, i + 1);
  }

  return current;
}

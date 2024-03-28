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
    final List<Map> currentItemList = List<Map>.from(_formData[event.sharedDataKey] ?? []);
    final hasValue = currentItemList.isNotEmpty && currentItemList.any((element) => element[_Constants.keyItemIdentifier] == event.itemIdentifierKey);

    if (hasValue) {
      currentItemList.removeWhere((currentItem) => currentItem[_Constants.keyItemIdentifier] == event.itemIdentifierKey);
    }
    currentItemList.add({_Constants.keyItemIdentifier: event.itemIdentifierKey}..addAll(event.value));

    _formData[event.sharedDataKey] = currentItemList;

    if (event.isInitialValue) {
      _formInitialData[event.sharedDataKey] = currentItemList;
    }
  }

  void _onNeoPageEventAddParametersWithPath(NeoPageEventAddParametersWithPath event, Emitter<NeoPageState> emit) {
    final RegExp pathPartPattern = RegExp(r'\[([0-9]+)\]|[^\.]+');
    final Iterable<Match> matches = pathPartPattern.allMatches(event.dataPath);
    final List<dynamic> path = [];

    for (Match match in matches) {
      if (match.group(1) != null) {
        path.add(int.parse(match.group(1) ?? ""));
      } else if (match.group(0) != '\$') {
        path.add(match.group(0));
      }
    }

    void setNestedMapValue(Map map, List<dynamic> path, dynamic value) {
      dynamic current = map;

      for (int i = 0; i < path.length; i++) {
        if (i == path.length - 1) {
          if (current is List) {
            if (value is Map && current[path[i]] is Map) {
              current[path[i]].addAll(value); // Merge the maps if both the current value and the new value are maps
            } else {
              current[path[i]] = value;
            }
          } else if (current is Map) {
            if (value is Map && current[path[i]] is Map) {
              current[path[i]].addAll(value); // Merge the maps if both the current value and the new value are maps
            } else {
              current[path[i]] = value;
            }
          }
        } else {
          if (current[path[i]] is Map) {
            current = current[path[i]];
          } else if (current[path[i]] is List) {
            current = current[path[i]];
          }
        }
      }
    }

    setNestedMapValue(_formData, path, event.value);
  }
}

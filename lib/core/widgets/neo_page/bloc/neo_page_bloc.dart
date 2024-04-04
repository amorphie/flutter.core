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
  }

  void _onAddParametersIntoArray(NeoPageEventAddParametersIntoArray event, Emitter<NeoPageState> emit) {
    final List<Map> currentItemList = List<Map>.from(_formData[event.sharedDataKey] ?? []);
    final hasValue = currentItemList.isNotEmpty &&
        currentItemList.any((element) => element[_Constants.keyItemIdentifier] == event.itemIdentifierKey);

    if (hasValue) {
      currentItemList
          .removeWhere((currentItem) => currentItem[_Constants.keyItemIdentifier] == event.itemIdentifierKey);
    }
    currentItemList.add({_Constants.keyItemIdentifier: event.itemIdentifierKey}..addAll(event.value));

    _formData[event.sharedDataKey] = currentItemList;

    if (event.isInitialValue) {
      _formInitialData[event.sharedDataKey] = currentItemList;
    }
  }

  Map<String, dynamic> getChangedFormData() {
    final Map<String, dynamic> stateDifference = {};

    formData.forEach((key, value) {
      if (_formInitialData.containsKey(key)) {
        if (value is List) {
          final List<dynamic> initialList = _formInitialData[key] ?? [];
          final List<dynamic> updatedList = value;

          final List<dynamic> diffList = updatedList.where((item) => !initialList.contains(item)).toList();

          if (diffList.isNotEmpty) {
            stateDifference[key] = diffList;
          }
        } else if (!const DeepCollectionEquality.unordered().equals(formData[key], _formInitialData[key])) {
          stateDifference[key] = formData[key];
        }
      } else {
        stateDifference[key] = formData[key];
      }
    });

    return stateDifference;
  }
}

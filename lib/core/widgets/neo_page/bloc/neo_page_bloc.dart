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
  bool _isStateChanged = false;

  bool get isStateChanged => _isStateChanged;

  Map<String, dynamic> get formData => _formData;

  NeoPageBloc() : super(const NeoPageState()) {
    on<NeoPageEventResetForm>((event, emit) {
      formKey.currentState?.reset();
      _onValueChanged();
    });
    on<NeoPageEventAddInitialParameters>((event, emit) {
      _formInitialData.addAll(event.parameters);
      _formData.addAll(event.parameters);
    });
    on<NeoPageEventAddAllParameters>((event, emit) {
      _formData.addAll(event.parameters);
      _onValueChanged();
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
    _onValueChanged();
  }

  void _onValueChanged() {
    _isStateChanged = !const DeepCollectionEquality().equals(_formInitialData, _formData);
  }
}

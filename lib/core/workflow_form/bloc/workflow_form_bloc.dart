import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'workflow_form_event.dart';
part 'workflow_form_state.dart';

abstract class _Constants {
  static const String keyItemIdentifier = "itemIdentifierKey";
}

class WorkflowFormBloc extends Bloc<WorkflowFormEvent, WorkflowFormState> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final Map<String, dynamic> _formInitialData;
  final Map<String, dynamic> _formData = {};
  bool _isStateChanged = false;

  bool get isStateChanged => _isStateChanged;

  Map<String, dynamic> get formData => _formData;

  WorkflowFormBloc() : super(WorkflowFormInitial()) {
    on<WorkflowFormEventResetFrom>((event, emit) {
      formKey.currentState?.reset();
      _onValueChanged();
    });
    on<WorkflowFormEventAddInitialParameters>((event, emit) => _formInitialData = event.parameters);
    on<WorkflowFormEventAddAllParameters>((event, emit) {
      _formData.addAll(event.parameters);
      _onValueChanged();
    });
    on<WorkflowFormEventAddParametersIntoArray>(_onAddParametersIntoArray);
    on<WorkflowFormEventValidateForm>((event, emit) => formKey.currentState?.validate());
  }

  void _onAddParametersIntoArray(WorkflowFormEventAddParametersIntoArray event, Emitter<WorkflowFormState> emit) {
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
    _isStateChanged = _formInitialData == _formData;
  }
}

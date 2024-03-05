import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'workflow_form_event.dart';
part 'workflow_form_state.dart';

abstract class _Constants {
  static const String keyListItemId = "listItemId";
}

class WorkflowFormBloc extends Bloc<WorkflowFormEvent, WorkflowFormState> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};

  Map<String, dynamic> get formData => _formData;

  WorkflowFormBloc() : super(WorkflowFormInitial()) {
    on<WorkflowFormEventResetFrom>((event, emit) {
      formKey.currentState?.reset();
    });
    on<WorkflowFormEventUpdateTextFormField>((event, emit) {
      _onTextFormFieldUpdated(event);
    });
    on<WorkflowFormEventAddAllParameters>((event, emit) {
      _formData.addAll(event.parameters);
    });
    on<WorkflowFormEventAddParametersIntoArray>(_onAddParametersIntoArray);
    on<WorkflowFormEventValidateForm>((event, emit) {
      formKey.currentState?.validate();
    });
  }

  void _onTextFormFieldUpdated(WorkflowFormEventUpdateTextFormField event) {
    _formData[event.key] = event.value;
  }

  void _onAddParametersIntoArray(WorkflowFormEventAddParametersIntoArray event, Emitter<WorkflowFormState> emit) {
    final List<Map> currentItemList = _formData[event.dataKey] ?? <Map>[];
    final hasValue = currentItemList.isNotEmpty &&
        currentItemList.any((element) => element[_Constants.keyListItemId] == event.listItemId);
    if (hasValue) {
      currentItemList.removeWhere((currentItem) => currentItem[_Constants.keyListItemId] == event.listItemId);
    }
    currentItemList.add({_Constants.keyListItemId: event.listItemId}..addAll(event.value));

    _formData[event.dataKey] = [currentItemList];
  }
}

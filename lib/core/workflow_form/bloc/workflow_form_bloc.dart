import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'workflow_form_event.dart';
part 'workflow_form_state.dart';

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
    final value = _formData[event.key];
    final hasValue = value != null && value is List;
    if (hasValue) {
      value.add(event.value);
      _formData[event.key] = value;
    } else {
      _formData[event.key] = [event.value];
    }
  }
}

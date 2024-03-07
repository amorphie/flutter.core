part of 'workflow_form_bloc.dart';

sealed class WorkflowFormEvent extends Equatable {
  const WorkflowFormEvent();
}

class WorkflowFormEventUpdateTextFormField extends WorkflowFormEvent {
  final String key;
  final String value;

  const WorkflowFormEventUpdateTextFormField({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];
}

class WorkflowFormEventResetFrom extends WorkflowFormEvent {
  const WorkflowFormEventResetFrom();

  @override
  List<Object?> get props => [];
}

class WorkflowFormEventAddAllParameters extends WorkflowFormEvent {
  final Map<String, dynamic> parameters;

  const WorkflowFormEventAddAllParameters(this.parameters);

  @override
  List<Object?> get props => [parameters];
}

class WorkflowFormEventValidateForm extends WorkflowFormEvent {
  @override
  List<Object?> get props => [];
}

class WorkflowFormEventAddParametersIntoArray extends WorkflowFormEvent {
  final dynamic itemIdentifierKey;
  final String sharedDataKey;
  final Map value;

  const WorkflowFormEventAddParametersIntoArray(
      {required this.itemIdentifierKey, required this.sharedDataKey, required this.value});

  @override
  List<Object?> get props => [itemIdentifierKey, sharedDataKey, value];
}

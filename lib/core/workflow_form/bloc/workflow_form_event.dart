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
  final String listItemId;
  final String dataKey;
  final Map value;

  const WorkflowFormEventAddParametersIntoArray({required this.listItemId, required this.dataKey, required this.value});

  @override
  List<Object?> get props => [dataKey, value];
}

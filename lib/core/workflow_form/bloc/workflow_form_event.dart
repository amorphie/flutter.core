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

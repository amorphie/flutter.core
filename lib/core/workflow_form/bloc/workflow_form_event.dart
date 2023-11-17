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

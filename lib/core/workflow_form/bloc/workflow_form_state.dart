part of 'workflow_form_bloc.dart';

sealed class WorkflowFormState extends Equatable {
  const WorkflowFormState();
}

class WorkflowFormInitial extends WorkflowFormState {
  @override
  List<Object> get props => [];
}

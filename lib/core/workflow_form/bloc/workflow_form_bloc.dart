import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'workflow_form_event.dart';
part 'workflow_form_state.dart';

class WorkflowFormBloc extends Bloc<WorkflowFormEvent, WorkflowFormState> {
  final Map<String, dynamic> _formData = {};

  Map<String, dynamic> get formData => _formData;

  WorkflowFormBloc() : super(WorkflowFormInitial()) {
    on<WorkflowFormEventUpdateTextFormField>((event, emit) {
      _onTextFormFieldUpdated(event);
    });
  }

  void _onTextFormFieldUpdated(WorkflowFormEventUpdateTextFormField event) {
    _formData[event.key] = event.value;
  }
}

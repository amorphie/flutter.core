part of 'brg_component_tree_builder_bloc.dart';

sealed class BrgComponentTreeBuilderState extends Equatable {
  const BrgComponentTreeBuilderState();
}

class BrgComponentTreeBuilderStateLoading extends BrgComponentTreeBuilderState {
  @override
  List<Object> get props => [];
}

class BrgComponentTreeBuilderStateLoaded extends BrgComponentTreeBuilderState {
  final Map<String, dynamic> componentsMap;

  const BrgComponentTreeBuilderStateLoaded({required this.componentsMap});

  @override
  List<Object> get props => [componentsMap];
}

class BrgComponentTreeBuilderStateError extends BrgComponentTreeBuilderState {
  final String errorMessage;

  const BrgComponentTreeBuilderStateError({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}

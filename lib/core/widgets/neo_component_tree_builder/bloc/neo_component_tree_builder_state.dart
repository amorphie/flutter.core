part of 'neo_component_tree_builder_bloc.dart';

sealed class NeoComponentTreeBuilderState extends Equatable {
  const NeoComponentTreeBuilderState();
}

class NeoComponentTreeBuilderStateLoading extends NeoComponentTreeBuilderState {
  @override
  List<Object> get props => [];
}

class NeoComponentTreeBuilderStateLoaded extends NeoComponentTreeBuilderState {
  final Map<String, dynamic> componentsMap;

  const NeoComponentTreeBuilderStateLoaded({required this.componentsMap});

  @override
  List<Object> get props => [componentsMap];
}

class NeoComponentTreeBuilderStateError extends NeoComponentTreeBuilderState {
  final String errorMessage;

  const NeoComponentTreeBuilderStateError({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}

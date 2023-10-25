part of 'neo_component_tree_builder_bloc.dart';

sealed class NeoComponentTreeBuilderEvent extends Equatable {
  const NeoComponentTreeBuilderEvent();
}

class NeoComponentTreeBuilderEventFetchComponents extends NeoComponentTreeBuilderEvent {
  final String pageId;

  const NeoComponentTreeBuilderEventFetchComponents({required this.pageId});

  @override
  List<Object?> get props => [pageId];
}

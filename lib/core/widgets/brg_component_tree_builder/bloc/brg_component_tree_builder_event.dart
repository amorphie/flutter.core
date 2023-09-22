part of 'brg_component_tree_builder_bloc.dart';

sealed class BrgComponentTreeBuilderEvent extends Equatable {
  const BrgComponentTreeBuilderEvent();
}

class BrgComponentTreeBuilderEventFetchComponents extends BrgComponentTreeBuilderEvent {
  final String pageId;

  const BrgComponentTreeBuilderEventFetchComponents({required this.pageId});

  @override
  List<Object?> get props => [pageId];
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:neo_core/neo_core.dart';

class NeoComponentTreeBuilder extends StatelessWidget {
  final IComponentsNetworkManager componentsNetworkManager;
  final String pageId;
  final Widget loadingWidget;
  final Widget errorWidget;

  const NeoComponentTreeBuilder({
    required this.componentsNetworkManager,
    required this.pageId,
    this.loadingWidget = const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Center(child: CircularProgressIndicator())],
    ),
    this.errorWidget = const SizedBox.shrink(),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NeoComponentTreeBuilderBloc, NeoComponentTreeBuilderState>(
      bloc: NeoComponentTreeBuilderBloc(componentsNetworkManager)
        ..add(NeoComponentTreeBuilderEventFetchComponents(pageId: pageId)),
      builder: (context, state) {
        switch (state) {
          case NeoComponentTreeBuilderStateLoading _:
            return loadingWidget;
          case NeoComponentTreeBuilderStateLoaded _:
            return JsonWidgetData.fromDynamic(state.componentsMap)?.build(context: context) ?? const SizedBox.shrink();
          case NeoComponentTreeBuilderStateError _:
            return errorWidget;
        }
      },
    );
  }
}

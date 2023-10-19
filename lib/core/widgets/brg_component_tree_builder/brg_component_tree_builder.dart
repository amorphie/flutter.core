import 'package:burgan_core/burgan_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

class BrgComponentTreeBuilder extends StatelessWidget {
  final IComponentsNetworkManager componentsNetworkManager;
  final String pageId;
  final Widget loadingWidget;
  final Widget errorWidget;

  const BrgComponentTreeBuilder({
    Key? key,
    required this.componentsNetworkManager,
    required this.pageId,
    this.loadingWidget = const Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Center(child: CircularProgressIndicator())],
    ),
    this.errorWidget = const SizedBox.shrink(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrgComponentTreeBuilderBloc, BrgComponentTreeBuilderState>(
      bloc: BrgComponentTreeBuilderBloc(componentsNetworkManager)
        ..add(BrgComponentTreeBuilderEventFetchComponents(pageId: pageId)),
      builder: (context, state) {
        switch (state) {
          case BrgComponentTreeBuilderStateLoading _:
            return loadingWidget;
          case BrgComponentTreeBuilderStateLoaded _:
            return JsonWidgetData.fromDynamic(state.componentsMap)?.build(context: context) ?? const SizedBox.shrink();
          case BrgComponentTreeBuilderStateError _:
            return errorWidget;
        }
      },
    );
  }
}

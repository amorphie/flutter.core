import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:neo_core/core/widgets/neo_navigation_button/neo_navigation_button.dart';

part 'neo_navigation_button_builder.g.dart';

@JsonWidget(type: 'neo_navigation_button')
abstract class _NeoNavigationButtonBuilder extends JsonWidgetBuilder {
  const _NeoNavigationButtonBuilder({required super.args});

  @override
  NeoNavigationButton buildCustom({
    required BuildContext context,
    required JsonWidgetData data,
    ChildWidgetBuilder? childBuilder,
    Key? key,
  });
}

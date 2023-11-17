import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:neo_core/core/widgets/neo_transition_button/neo_transition_button.dart';

part 'neo_transition_button_builder.g.dart';

@JsonWidget(type: 'neo_transition_button')
abstract class _NeoTransitionButtonBuilder extends JsonWidgetBuilder {
  const _NeoTransitionButtonBuilder({required super.args});

  @override
  NeoTransitionButton buildCustom({
    required BuildContext context,
    required JsonWidgetData data,
    ChildWidgetBuilder? childBuilder,
    Key? key,
  });
}

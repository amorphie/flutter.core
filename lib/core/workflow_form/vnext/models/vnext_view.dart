import 'package:neo_core/core/workflow_form/vnext/models/vnext_view_display_mode.dart';

class VNextView {
  final String pageId;

  final Map<String, dynamic> content;

  final VNextViewDisplayMode displayType;

  VNextView({required this.pageId, required this.content, required this.displayType});
}

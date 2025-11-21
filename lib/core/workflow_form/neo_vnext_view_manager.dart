import 'dart:convert';

import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_view.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_view_display_mode.dart';

class NeoVNextViewManager {
  static const viewSource = "vnext";

  final NeoNetworkManager neoNetworkManager;

  NeoVNextViewManager(this.neoNetworkManager);

  final Map<String, VNextView> _viewCache = {};

  Map<String, dynamic> getViewByInstanceId(String instanceId) {
    return _viewCache[instanceId]?.content ?? {};
  }

  Future<VNextView?> fetchViewByHref({required String href}) async {
    final response = await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: "vnext-get-workflow-instance-view-by-href",
        pathParameters: {
          "HREF": href,
        },
        useHttps: false, // TODO STOPSHIP: Delete it when APIs are deployed
      ),
    );
    if (response.isSuccess) {
      return _cacheViewByInstanceId(_extractInstanceId(href), response.asSuccess.data);
    }
    return null;
  }

  /// Call this method when workflow is completed for the instance
  void deleteViewFromCache(String instanceId) {
    _viewCache.remove(instanceId);
  }

  VNextView? _cacheViewByInstanceId(String? instanceId, Map viewResponse) {
    if (instanceId == null) {
      return null;
    }
    final content = viewResponse["content"] is Map ? viewResponse["content"] : jsonDecode(viewResponse["content"]);
    final view = VNextView(
      pageId: content["pageName"],
      content: content["componentJson"],
      displayType: VNextViewDisplayMode.fromString(viewResponse["display"]),
    );
    _viewCache[instanceId] = view;
    return view;
  }

  String? _extractInstanceId(String href) {
    return RegExp(r'/instances/([a-f0-9\-]+)/').firstMatch(href)?.group(1);
  }
}

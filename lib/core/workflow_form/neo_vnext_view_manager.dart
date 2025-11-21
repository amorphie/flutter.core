import 'dart:convert';

import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_view.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_view_display_mode.dart';

class NeoVNextViewManager {
  final NeoNetworkManager neoNetworkManager;

  NeoVNextViewManager(this.neoNetworkManager);

  final Map<String, VNextView> _viewCache = {};

  Future<NeoResponse> fetchViewByHref({required String href}) async {
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
      _cacheViewByInstanceId(_extractInstanceId(href), response.asSuccess.data);
    }
    return response;
  }

  /// Call this method when workflow is completed for the instance
  void deleteViewFromCache(String instanceId) {
    _viewCache.remove(instanceId);
  }

  void _cacheViewByInstanceId(String? instanceId, Map viewResponse) {
    if (instanceId == null) {
      return;
    }
    final content = viewResponse["content"] is Map ? viewResponse["content"] : jsonDecode(viewResponse["content"]);
    _viewCache[instanceId] = VNextView(
      pageId: content["pageName"],
      content: content["componentJson"],
      displayType: VNextViewDisplayMode.fromString(viewResponse["display"]),
    );
  }

  String? _extractInstanceId(String href) {
    return RegExp(r'/instances/([a-f0-9\-]+)/').firstMatch(href)?.group(1);
  }
}

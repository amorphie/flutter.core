import 'dart:async';

import 'package:neo_core/core/analytics/neo_analytics.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_core_widget_event_keys.dart';
import 'package:neo_core/core/environment_variables/neo_environment.dart';
import 'package:neo_core/core/environment_variables/neo_environment_type.dart';
import 'package:neo_core/core/managers/dengage_manager/dengage_manager.dart';
import 'package:neo_core/core/managers/nba_manager/models/neo_nba_content_type.dart';
import 'package:neo_core/core/managers/nba_manager/models/neo_nba_item.dart';
import 'package:neo_core/core/managers/parameter_manager/neo_core_parameter_key.dart';
import 'package:neo_core/core/managers/parameter_manager/neo_parameter_manager.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/neo_core.dart';

export 'package:neo_core/core/managers/nba_manager/models/neo_nba_content_type.dart';
export 'package:neo_core/core/managers/nba_manager/models/neo_nba_item.dart';
export 'package:neo_core/core/managers/nba_manager/models/neo_nba_item_action.dart';
export 'package:neo_core/core/managers/nba_manager/models/neo_nba_item_content.dart';
export 'package:neo_core/core/managers/nba_manager/models/neo_nba_item_type.dart';

abstract class _Constants {
  static const String nbaContentEndpoint = "get-nba-content";
}

/// NBA means Next Best Action in marketing terminology
class NeoNbaManager {
  final NeoNetworkManager networkManager;
  final NeoParameterManager neoParameterManager;

  /// This map is used to store the futures of the items that are fetched by page id (toPage).
  final Map<String, Future<List<NeoNbaItem>>> _fetchItemsByPageIdFutures = {};

  NeoNbaManager({
    required this.networkManager,
    required this.neoParameterManager,
  });

  Future<NeoNbaItem?> getContent({required String pageId, required int index, NeoNbaContentType? contentType}) async {
    final items = await _fetchItemsByPageIdFutures[pageId] ?? [];
    final filteredItems =
        contentType != null ? items.where((e) => e.content.contentType == contentType).toList() : items;
    return filteredItems.length > index ? filteredItems[index] : null;
  }

  Future<List<NeoNbaItem>> getContents({required String pageId, NeoNbaContentType? contentType}) async {
    final items = await _fetchItemsByPageIdFutures[pageId] ?? [];
    final filteredItems =
        contentType != null ? items.where((e) => e.content.contentType == contentType).toList() : items;
    return filteredItems;
  }

  void deleteAllContentsByPageId(String pageId) {
    _fetchItemsByPageIdFutures.remove(pageId);
  }

  void sendNavigationEvent({
    required String fromPage,
    required String toPage,
  }) {
    if (toPage.isEmpty) {
      return;
    }

    if (NeoEnvironment.current.isOn) {
      _fetchItemsByPageIdFutures[toPage] = _fetchNbaContentList(fromPage: fromPage, toPage: toPage);
    }

    DengageManager.setNavigationWithName(toPage);
    _reportToDataroid(fromPage, toPage);
  }

  Future<List<NeoNbaItem>> _fetchNbaContentList({required String fromPage, required String toPage}) async {
    final response = await networkManager.call(
      NeoHttpCall(
        endpoint: _Constants.nbaContentEndpoint,
        body: {
          "fromRoute": fromPage,
          "toRoute": toPage,
          "customerNo": await neoParameterManager.read(NeoCoreParameterKey.secureStorageCustomerNo),
          "customerIdentity": await neoParameterManager.read(NeoCoreParameterKey.secureStorageCustomerId),
          "fromRoutePayload": const {},
          "topic": "app-navigation",
        },
      ),
    );
    if (response.isError) {
      return [];
    }
    final items = (response.asSuccess.data["data"] as List).map((e) => NeoNbaItem.fromJson(e)).toList();
    return items..sort((a, b) => a.order.compareTo(b.order));
  }

  void _reportToDataroid(String fromPage, String toPage) {
    NeoCoreWidgetEventKeys.globalAnalyticEvent
      ..sendEvent(data: NeoAnalyticEventStopScreenTracking(label: fromPage))
      ..sendEvent(
        data: NeoAnalyticEventStartScreenTracking(
          label: toPage,
          viewClass: toPage,
          attributes: {
            "from_page": fromPage,
            "to_page": toPage,
          },
        ),
      );
  }
}

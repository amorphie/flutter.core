import 'package:neo_core/core/analytics/neo_analytics.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_core_widget_event_keys.dart';

mixin NeoNbaAnalyticsMixin {
  void sendInAppDisplayEvent({
    required int? bannerId,
    required String pageId,
    required String bannerUrl,
    String? contentTitle,
    String? contentBody,
    int? contentType,
  }) {
    _sendEvent(
      eventName: "NBAInAppDisplayEvent",
      bannerId: bannerId,
      pageId: pageId,
      bannerUrl: bannerUrl,
      contentTitle: contentTitle,
      contentBody: contentBody,
      contentType: contentType,
    );
  }

  void sendInAppClickEvent({
    required int? bannerId,
    required String pageId,
    required String bannerUrl,
    String? contentTitle,
    String? contentBody,
    int? contentType,
    int? actionType,
    String? actionLink,
  }) {
    _sendEvent(
      eventName: "NBAInAppClickEvent",
      bannerId: bannerId,
      pageId: pageId,
      bannerUrl: bannerUrl,
      contentTitle: contentTitle,
      contentBody: contentBody,
      contentType: contentType,
      actionType: actionType,
      actionLink: actionLink,
    );
  }

  void sendBannerDisplayEvent({
    required int? bannerId,
    required String pageId,
    required String bannerUrl,
    String? contentTitle,
    String? contentBody,
    int? contentType,
  }) {
    _sendEvent(
      eventName: "NBABannerReadEvent",
      bannerId: bannerId,
      pageId: pageId,
      bannerUrl: bannerUrl,
      contentTitle: contentTitle,
      contentBody: contentBody,
      contentType: contentType,
    );
  }

  void sendBannerClickEvent({
    required int? bannerId,
    required String pageId,
    required String bannerUrl,
    String? contentTitle,
    String? contentBody,
    int? contentType,
    int? actionType,
    String? actionLink,
  }) {
    _sendEvent(
      eventName: "NBABannerClickEvent",
      bannerId: bannerId,
      pageId: pageId,
      bannerUrl: bannerUrl,
      contentTitle: contentTitle,
      contentBody: contentBody,
      contentType: contentType,
      actionType: actionType,
      actionLink: actionLink,
    );
  }

  void _sendEvent({
    required String eventName,
    required int? bannerId,
    required String pageId,
    required String bannerUrl,
    String? contentTitle,
    String? contentBody,
    int? contentType,
    int? actionType,
    String? actionLink,
  }) {
    NeoCoreWidgetEventKeys.globalAnalyticEvent.sendEvent(
      data: NeoAnalyticEventCustomEvent(
        eventName: eventName,
        attributes: {
          "bannerId": bannerId,
          "pageId": pageId,
          "bannerUrl": bannerUrl,
          "content": {
            "title": contentTitle ?? "",
            "body": contentBody ?? "",
            "contentType": contentType,
          },
          "action": {
            "actionType": actionType,
            "actionLink": actionLink,
          },
        },
      ),
    );
  }
}

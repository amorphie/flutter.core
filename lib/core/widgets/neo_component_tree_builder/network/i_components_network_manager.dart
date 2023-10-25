import 'package:neo_core/core/network/models/neo_response.dart';

abstract class IComponentsNetworkManager {
  IComponentsNetworkManager();

  Future<NeoResponse> fetchPageComponentsByPageId(String pageId);
}

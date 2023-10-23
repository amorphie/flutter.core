import 'package:burgan_core/core/network/models/neo_response.dart';
import 'package:burgan_core/core/widgets/brg_component_tree_builder/network/models/neo_page_components_response.dart';

abstract class IComponentsNetworkManager {
  IComponentsNetworkManager();

  Future<NeoResponse<NeoPageComponentsResponse>> fetchPageComponentsByPageId(String pageId);
}

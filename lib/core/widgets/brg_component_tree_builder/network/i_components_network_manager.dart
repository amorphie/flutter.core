abstract class IComponentsNetworkManager {
  IComponentsNetworkManager();

  Future<Map<String, dynamic>> fetchPageComponentsByPageId(String pageId);
}

import 'package:burgan_core/burgan_core.dart';

abstract class IComponentsNetworkManager extends NetworkManager {
  final String baseUrl;

  IComponentsNetworkManager({required this.baseUrl}) : super(baseURL: baseUrl);

  Future<Map<String, dynamic>> fetchPageComponentsByPageId(String pageId);
}

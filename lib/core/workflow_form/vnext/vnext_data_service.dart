/*
 * neo_core
 *
 * VNext Data Service: fetches view and data via hrefs and normalizes to { body: ... }
 */

import 'dart:convert';

import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/models/neo_error.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_instance_snapshot.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_client.dart';

class VNextDataService {
  final VNextWorkflowClient _client;
  final NeoLogger _logger;

  VNextDataService({required VNextWorkflowClient client, required NeoLogger logger})
      : _client = client,
        _logger = logger;

  /// Load view (and optionally data) based on snapshot hrefs and normalize to { body: ... }
  Future<NeoResponse> loadView({
    required VNextInstanceSnapshot snapshot,
    Map<String, String>? headers,
  }) async {
    print('[VNextDataService] ===== LOADING VIEW =====');
    print('[VNextDataService] Instance ID: ${snapshot.instanceId}');
    print('[VNextDataService] State: ${snapshot.state}');
    print('[VNextDataService] Workflow: ${snapshot.workflowName}');
    print('[VNextDataService] Domain: ${snapshot.domain}');
    
    final String? viewHref = snapshot.viewHref;
    final String? dataHref = snapshot.dataHref;
    final bool loadData = snapshot.loadData;
    
    print('[VNextDataService] View Href: $viewHref');
    print('[VNextDataService] Data Href: $dataHref');
    print('[VNextDataService] Load Data: $loadData');
    print('[VNextDataService] Headers: $headers');

    _logger.logConsole('[VNextDataService] loadView(state=${snapshot.state}, loadData=$loadData, instanceId=${snapshot.instanceId})');

    try {
      Map<String, dynamic>? dataPayload;

      if (loadData && dataHref != null && dataHref.isNotEmpty) {
        print('[VNextDataService] ===== FETCHING DATA =====');
        print('[VNextDataService] Data URL: $dataHref');
        _logger.logConsole('[VNextDataService] Fetching data via href: $dataHref');
        final dataResp = await _client.fetchByPath(href: dataHref, headers: headers);
        if (dataResp.isSuccess) {
          dataPayload = dataResp.asSuccess.data;
          print('[VNextDataService] Data fetch SUCCESS');
          print('[VNextDataService] Data payload: $dataPayload');
          _logger.logConsole('[VNextDataService] Data fetch success');
        } else {
          print('[VNextDataService] Data fetch ERROR: ${dataResp.asError.error.error.description}');
          _logger.logConsole('[VNextDataService] Data fetch error: ${dataResp.asError.error.error.description}');
        }
      } else {
        print('[VNextDataService] Skipping data fetch (loadData=$loadData, dataHref=$dataHref)');
      }

      if (viewHref == null || viewHref.isEmpty) {
        print('[VNextDataService] ERROR: Missing viewHref!');
        _logger.logError('[VNextDataService] Missing viewHref for state=${snapshot.state}, instanceId=${snapshot.instanceId}');
        return NeoResponse.error(
          const NeoError(error: NeoErrorDetail(description: 'Missing view href')),
          responseHeaders: const {},
        );
      }

      print('[VNextDataService] ===== FETCHING VIEW =====');
      print('[VNextDataService] View URL: $viewHref');
      _logger.logConsole('[VNextDataService] Fetching view via href: $viewHref');
      final viewResp = await _client.fetchByPath(href: viewHref, headers: headers);
      
      if (viewResp.isError) {
        print('[VNextDataService] View fetch ERROR: ${viewResp.asError.error.error.description}');
        _logger.logError('[VNextDataService] View fetch error: ${viewResp.asError.error.error.description}');
        return viewResp;
      }

      print('[VNextDataService] View fetch SUCCESS');
      print('[VNextDataService] Raw view response: ${viewResp.asSuccess.data}');
      
      print('[VNextDataService] ===== NORMALIZING VIEW =====');
      final normalized = _normalizeViewResponse(viewResp.asSuccess.data, dataPayload, snapshot);
      if (normalized == null) {
        print('[VNextDataService] ERROR: View normalization failed!');
        _logger.logError('[VNextDataService] Failed to normalize view response');
        return NeoResponse.error(
          const NeoError(error: NeoErrorDetail(description: 'View normalization failed')),
          responseHeaders: const {},
        );
      }

      print('[VNextDataService] View normalization SUCCESS');
      print('[VNextDataService] Normalized response: $normalized');
      print('[VNextDataService] ===== VIEW LOADING COMPLETE =====');

      return NeoResponse.success(normalized, statusCode: 200, responseHeaders: const {});
    } catch (e) {
      print('[VNextDataService] EXCEPTION during view loading: $e');
      print('[VNextDataService] Exception type: ${e.runtimeType}');
      _logger.logError('[VNextDataService] Exception while loading view: $e');
      return NeoResponse.error(
        NeoError(error: NeoErrorDetail(description: 'Exception: $e')),
        responseHeaders: const {},
      );
    }
  }

  Map<String, dynamic>? _normalizeViewResponse(
    dynamic rawView,
    Map<String, dynamic>? rawData,
    VNextInstanceSnapshot snapshot,
  ) {
    print('[VNextDataService] ===== NORMALIZING VIEW RESPONSE =====');
    print('[VNextDataService] Raw view type: ${rawView.runtimeType}');
    print('[VNextDataService] Raw view: $rawView');
    print('[VNextDataService] Raw data: $rawData');
    
    try {
      // Strict schema: { view: { content: { pageName, componentJson }}, type: Json, target: State }
      if (rawView is! Map<String, dynamic>) {
        print('[VNextDataService] ERROR: View response is not a Map!');
        _logger.logError('[VNextDataService] View response is not a Map for state=${snapshot.state}');
        return null;
      }
      
      print('[VNextDataService] View response is Map, extracting view...');
      final view = rawView['view'];
      print('[VNextDataService] View: $view');
      
      if (view is! Map<String, dynamic>) {
        print('[VNextDataService] ERROR: Missing view in response!');
        _logger.logError('[VNextDataService] Missing view in response for state=${snapshot.state}');
        return null;
      }
      
      print('[VNextDataService] View is Map, extracting content...');
      final content = view['content'];
      print('[VNextDataService] Content: $content');
      
      if (content is! Map<String, dynamic>) {
        print('[VNextDataService] ERROR: Missing content in view!');
        _logger.logError('[VNextDataService] Missing content in view for state=${snapshot.state}');
        return null;
      }
      
      print('[VNextDataService] Content is Map, extracting pageName and componentJson...');
      final pageName = content['pageName'];
      final componentJson = content['componentJson'];
      print('[VNextDataService] Page name: $pageName');
      print('[VNextDataService] Component JSON type: ${componentJson.runtimeType}');
      print('[VNextDataService] Component JSON: $componentJson');
      
      if (pageName is! String || componentJson is! Map<String, dynamic>) {
        print('[VNextDataService] ERROR: Invalid view schema!');
        print('[VNextDataService] Page name type: ${pageName.runtimeType}');
        print('[VNextDataService] Component JSON type: ${componentJson.runtimeType}');
        _logger.logError('[VNextDataService] Invalid view schema: pageName or componentJson missing for state=${snapshot.state}');
        return null;
      }

      // Optionally parse data model if present
      VNextDataModel? dataModel;
      if (rawData != null) {
        print('[VNextDataService] Parsing data model...');
        dataModel = _parseDataModel(rawData, snapshot);
        if (dataModel != null) {
          print('[VNextDataService] Data model parsed successfully with eTag=${dataModel.eTag}');
          _logger.logConsole('[VNextDataService] Parsed data model with eTag=${dataModel.eTag} for state=${snapshot.state}');
        } else {
          print('[VNextDataService] Data model parsing failed');
        }
      } else {
        print('[VNextDataService] No raw data to parse');
      }

      // Return normalized renderer payload
      final result = { 'body': componentJson };
      print('[VNextDataService] Normalized result: $result');
      print('[VNextDataService] ===== VIEW NORMALIZATION SUCCESS =====');
      return result;
    } catch (e) {
      print('[VNextDataService] EXCEPTION during view normalization: $e');
      print('[VNextDataService] Exception type: ${e.runtimeType}');
      _logger.logError('[VNextDataService] View normalization error: $e');
      return null;
    }
  }

  Map<String, dynamic>? _extractComponentJson(dynamic any) {
    try {
      dynamic content = any;
      if (content is String) {
        try {
          content = jsonDecode(content);
        } catch (e) {
          _logger.logError('[VNextDataService] JSON decode error in extractComponentJson: $e');
        }
      }

      if (content is Map<String, dynamic>) {
        final comp = content['componentJson'] ?? content['body'] ?? content;
        if (comp is Map<String, dynamic>) return comp;
      }
    } catch (e) {
      _logger.logError('[VNextDataService] extractComponentJson error: $e');
    }
    return null;
  }

  VNextDataModel? _parseDataModel(Map<String, dynamic> raw, VNextInstanceSnapshot snapshot) {
    try {
      final data = raw['data'];
      if (data is! Map<String, dynamic>) {
        _logger.logError('[VNextDataService] Missing data root for state=${snapshot.state}');
        return null;
      }
      final attrs = data['attributes'];
      final eTag = data['etag'];
      if (attrs is! Map<String, dynamic> || eTag is! String) {
        _logger.logError('[VNextDataService] Invalid data schema (attributes/etag) for state=${snapshot.state}');
        return null;
      }
      return VNextDataModel(attributes: attrs, eTag: eTag);
    } catch (e) {
      _logger.logError('[VNextDataService] Data parsing error: $e');
      return null;
    }
  }
}

class VNextViewModel {
  final Map<String, dynamic> componentJson;
  final String pageName;
  const VNextViewModel({required this.componentJson, required this.pageName});
}

class VNextDataModel {
  final Map<String, dynamic> attributes;
  final String eTag;
  const VNextDataModel({required this.attributes, required this.eTag});
}

class VNextRenderBundle {
  final VNextViewModel view;
  final VNextDataModel? data;
  final String state;
  final String instanceId;
  const VNextRenderBundle({required this.view, required this.data, required this.state, required this.instanceId});
}

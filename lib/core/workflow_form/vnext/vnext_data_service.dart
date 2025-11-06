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
    _logger.logConsole('[VNextDataService] loadView start instanceId=${snapshot.instanceId} state=${snapshot.state}');
    
    final String? viewHref = snapshot.viewHref;
    final String? dataHref = snapshot.dataHref;
    final bool loadData = snapshot.loadData;
    
    _logger.logConsole('[VNextDataService] hrefs view=$viewHref data=$dataHref loadData=$loadData');

    try {
      Map<String, dynamic>? dataPayload;

      if (loadData && dataHref != null && dataHref.isNotEmpty) {
        _logger.logConsole('[VNextDataService] Fetching data via href: $dataHref');
        final dataResp = await _client.fetchByPath(href: dataHref, headers: headers);
        if (dataResp.isSuccess) {
          dataPayload = dataResp.asSuccess.data;
          _logger.logConsole('[VNextDataService] Data fetch successful, keys: ${dataPayload.keys.join(", ")}');
        } else {
          _logger.logError('[VNextDataService] Data fetch error: ${dataResp.asError.error.error.description}');
        }
      } else {
        _logger.logConsole('[VNextDataService] Skipping data fetch (loadData=$loadData, dataHref=$dataHref)');
      }

      if (viewHref == null || viewHref.isEmpty) {
        _logger.logError('[VNextDataService] Missing viewHref for state=${snapshot.state}, instanceId=${snapshot.instanceId}');
        return NeoResponse.error(
          const NeoError(error: NeoErrorDetail(description: 'Missing view href')),
          responseHeaders: const {},
        );
      }

      _logger.logConsole('[VNextDataService] Fetching view via href: $viewHref');
      final viewResp = await _client.fetchByPath(href: viewHref, headers: headers);
      
      if (viewResp.isError) {
        _logger.logError('[VNextDataService] View fetch error: ${viewResp.asError.error.error.description}');
        return viewResp;
      }

      _logger.logConsole('[VNextDataService] View fetch successful');

      final normalized = _normalizeViewResponse(viewResp.asSuccess.data, dataPayload, snapshot);
      if (normalized == null) {
        _logger.logError('[VNextDataService] Failed to normalize view response');
        return NeoResponse.error(
          const NeoError(error: NeoErrorDetail(description: 'View normalization failed')),
          responseHeaders: const {},
        );
      }

      return NeoResponse.success(normalized, statusCode: 200, responseHeaders: const {});
    } catch (e) {
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
    _logger.logConsole('[VNextDataService] normalize view response');
    
    try {
      if (rawView is! Map<String, dynamic>) {
        _logger.logError('[VNextDataService] View response is not a Map for state=${snapshot.state}');
        return null;
      }
      
      // New structure: { key: "...", content: "{...}", type: "Json" }
      // where content is a JSON string
      final content = rawView['content'];
      if (content is! String) {
        _logger.logError('[VNextDataService] Content is not a string for state=${snapshot.state}, type: ${content.runtimeType}');
        return null;
      }
      
      // Parse the JSON string
      Map<String, dynamic> contentMap;
      try {
        contentMap = jsonDecode(content) as Map<String, dynamic>;
        _logger.logConsole('[VNextDataService] Parsed content JSON string for state=${snapshot.state}');
      } catch (e) {
        _logger.logError('[VNextDataService] Failed to parse content JSON string for state=${snapshot.state}: $e');
        return null;
      }
      
      final pageName = contentMap['pageName'] as String?;
      final componentJson = contentMap['componentJson'] as Map<String, dynamic>?;
      
      if (pageName == null || componentJson == null) {
        _logger.logError('[VNextDataService] Invalid view schema: pageName or componentJson missing for state=${snapshot.state}');
        return null;
      }

      // Optionally parse data model if present
      VNextDataModel? dataModel;
      if (rawData != null) {
        _logger.logConsole('[VNextDataService] Parsing data model');
        dataModel = _parseDataModel(rawData, snapshot);
        if (dataModel != null) {
          _logger.logConsole('[VNextDataService] Data model parsed successfully, eTag=${dataModel.eTag}, attributes: ${dataModel.attributes.keys.join(", ")}');
        } else {
          _logger.logError('[VNextDataService] Data model parsing failed');
        }
      }

      // Return normalized renderer payload with data attributes for formData population
      final result = <String, dynamic>{
        'body': componentJson,
        if (dataModel != null) 'dataAttributes': dataModel.attributes,
      };
      _logger.logConsole('[VNextDataService] View normalized successfully, result keys: ${result.keys.join(", ")}');
      return result;
    } catch (e) {
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
        _logger.logError('[VNextDataService] Missing or invalid data root for state=${snapshot.state}, type: ${data.runtimeType}');
        return null;
      }
      
      final attrs = data['attributes'];
      final eTag = data['etag'] ?? data['eTag'];
      
      if (attrs is! Map<String, dynamic> || eTag is! String) {
        _logger.logError('[VNextDataService] Invalid data schema for state=${snapshot.state}, attrs type: ${attrs.runtimeType}, eTag type: ${eTag.runtimeType}');
        return null;
      }
      
      return VNextDataModel(attributes: attrs, eTag: eTag);
    } catch (e, stackTrace) {
      _logger.logError('[VNextDataService] Data parsing error: $e');
      _logger.logError('[VNextDataService] Stack trace: $stackTrace');
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

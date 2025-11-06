/*
 * neo_core
 * */

import 'package:equatable/equatable.dart';

enum VNextInstanceStatus {
  busy('B'),
  active('A'),
  passive('P'),
  completed('C'),
  faulted('F');

  const VNextInstanceStatus(this.code);
  final String code;

  static VNextInstanceStatus fromCode(String? code) {
    switch ((code ?? '').toUpperCase()) {
      case 'B':
        return VNextInstanceStatus.busy;
      case 'A':
        return VNextInstanceStatus.active;
      case 'P':
        return VNextInstanceStatus.passive;
      case 'C':
        return VNextInstanceStatus.completed;
      case 'F':
        return VNextInstanceStatus.faulted;
      default:
        return VNextInstanceStatus.active; // safe default
    }
  }

  bool get isBusy => this == VNextInstanceStatus.busy;
  bool get isActive => this == VNextInstanceStatus.active;
  bool get isTerminal => this == VNextInstanceStatus.completed || this == VNextInstanceStatus.faulted;
}

class VNextInstanceSnapshot extends Equatable {
  final String instanceId;
  final String key;
  final String workflowName; // The name of the workflow (e.g., 'account-opening', 'oauth-workflow')
  final String domain;
  final String flowVersion;
  final String etag;
  final List<String> tags;
  final String state; // extensions.currentState
  final String statusCode; // extensions.status (A/B/C/E/...)
  final String? viewHref; // extensions.view.href
  final bool loadData; // extensions.view.loadData
  final String? dataHref; // extensions.data.href
  final List<Map<String, String>> transitions; // [{name, href}]
  final List<String> activeCorrelations;
  final DateTime timestamp;

  const VNextInstanceSnapshot({
    required this.instanceId,
    required this.key,
    required this.workflowName,
    required this.domain,
    required this.flowVersion,
    required this.etag,
    required this.tags,
    required this.state,
    required this.statusCode,
    required this.viewHref,
    required this.loadData,
    required this.dataHref,
    required this.transitions,
    required this.activeCorrelations,
    required this.timestamp,
  });

  factory VNextInstanceSnapshot.fromInstanceJson(Map<String, dynamic> json) {
    final view = (json['view'] as Map<String, dynamic>?) ?? const {};
    final dataFn = (json['data'] as Map<String, dynamic>?) ?? const {};
    final transitions = (json['transitions'] as List?)
            ?.whereType<Map>()
            .map((e) => {
                  'name': e['name']?.toString() ?? '',
                  'href': e['href']?.toString() ?? '',
                })
            .toList()
        ?? const <Map<String, String>>[];
    final extensions = (json['extensions'] as Map<String, dynamic>?) ?? const {};
    final activeCorrelations = (extensions['activeCorrelations'] as List?)
            ?.whereType<String>()
            .toList()
        ?? const <String>[];
    final tags = (json['tags'] as List?)
            ?.whereType<String>()
            .toList()
        ?? const <String>[];

    return VNextInstanceSnapshot(
      instanceId: (json['id'] as String?) ?? (json['instanceId'] as String?) ?? '',
      key: (json['key'] as String?) ?? '',
      workflowName: (json['flow'] as String?) ?? '', // FIXED: Extract from 'flow' field
      domain: (json['domain'] as String?) ?? '',
      flowVersion: (json['flowVersion'] as String?) ?? '',
      etag: (json['etag'] as String?) ?? '',
      tags: tags,
      state: (extensions['currentState'] as String?) ?? '',
      statusCode: (extensions['status'] as String?) ?? '',
      viewHref: view['href']?.toString(),
      loadData: (view['loadData'] as bool?) ?? false,
      dataHref: dataFn['href']?.toString(),
      transitions: transitions,
      activeCorrelations: activeCorrelations,
      timestamp: DateTime.now(),
    );
  }

  VNextInstanceStatus get status => VNextInstanceStatus.fromCode(statusCode);
  bool get hasView => (viewHref ?? '').isNotEmpty;
  bool get isRenderable => hasView && !status.isBusy;

  @override
  List<Object?> get props => [
        instanceId,
        key,
        workflowName,
        domain,
        flowVersion,
        etag,
        tags,
        state,
        statusCode,
        viewHref,
        loadData,
        dataHref,
        transitions,
        activeCorrelations,
        timestamp,
      ];
}

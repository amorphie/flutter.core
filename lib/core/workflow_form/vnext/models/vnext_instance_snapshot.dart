/*
 * neo_core
 *
 * Minimal vNext instance snapshot for long polling
 */

import 'package:equatable/equatable.dart';

class VNextInstanceSnapshot extends Equatable {
  final String instanceId;
  final String state; // extensions.currentState
  final String status; // extensions.status (A/B/C/E/...)
  final String? viewHref; // extensions.view.href
  final bool loadData; // extensions.view.loadData
  final String? dataHref; // extensions.data.href
  final List<Map<String, String>> transitions; // [{name, href}]
  final DateTime timestamp;
  final Map<String, dynamic> raw; // full response or extensions for diagnostics

  const VNextInstanceSnapshot({
    required this.instanceId,
    required this.state,
    required this.status,
    required this.viewHref,
    required this.loadData,
    required this.dataHref,
    required this.transitions,
    required this.timestamp,
    required this.raw,
  });

  factory VNextInstanceSnapshot.fromInstanceJson(Map<String, dynamic> json) {
    final extensions = (json['extensions'] as Map<String, dynamic>?) ?? const {};
    final view = (extensions['view'] as Map<String, dynamic>?) ?? const {};
    final dataFn = (extensions['data'] as Map<String, dynamic>?) ?? const {};
    final transitions = (extensions['transitions'] as List?)
            ?.whereType<Map>()
            .map((e) => {
                  'name': e['name']?.toString() ?? '',
                  'href': e['href']?.toString() ?? '',
                })
            .toList()
        ?? const <Map<String, String>>[];

    return VNextInstanceSnapshot(
      instanceId: (json['id'] as String?) ?? (json['instanceId'] as String?) ?? '',
      state: (extensions['currentState'] as String?) ?? '',
      status: (extensions['status'] as String?) ?? '',
      viewHref: view['href']?.toString(),
      loadData: (view['loadData'] as bool?) ?? false,
      dataHref: dataFn['href']?.toString(),
      transitions: transitions,
      timestamp: DateTime.now(),
      raw: json,
    );
  }

  @override
  List<Object?> get props => [
        instanceId,
        state,
        status,
        viewHref,
        loadData,
        dataHref,
        transitions,
        raw,
      ];
}



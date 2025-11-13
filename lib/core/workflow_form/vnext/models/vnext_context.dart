/*
 * neo_core
 */

class VNextContext {
  final String instanceId;
  final String domain;
  final String workflowName;
  final String? flowVersion;
  final String? transitionName; // Current transition name (optional, for transition context)

  const VNextContext({
    required this.instanceId,
    required this.domain,
    required this.workflowName,
    this.flowVersion,
    this.transitionName,
  });

  bool get isValid => instanceId.isNotEmpty && workflowName.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'instanceId': instanceId,
        'domain': domain,
        'workflowName': workflowName,
        if (flowVersion != null && flowVersion!.isNotEmpty) 'flowVersion': flowVersion,
        if (transitionName != null && transitionName!.isNotEmpty) 'transitionName': transitionName,
      };

  factory VNextContext.fromJson(Map<String, dynamic> json) => VNextContext(
        instanceId: (json['instanceId'] as String?) ?? '',
        domain: (json['domain'] as String?) ?? 'core',
        workflowName: (json['workflowName'] as String?) ?? '',
        flowVersion: json['flowVersion'] as String?,
        transitionName: json['transitionName'] as String?,
      );

  /// Create a copy with updated transition name
  VNextContext copyWith({String? transitionName}) => VNextContext(
        instanceId: instanceId,
        domain: domain,
        workflowName: workflowName,
        flowVersion: flowVersion,
        transitionName: transitionName ?? this.transitionName,
      );
}

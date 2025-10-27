/*
 * neo_core
 */

class VNextContext {
  final String instanceId;
  final String domain;
  final String workflowName;
  final String? flowVersion;

  const VNextContext({
    required this.instanceId,
    required this.domain,
    required this.workflowName,
    this.flowVersion,
  });

  bool get isValid => instanceId.isNotEmpty && workflowName.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'instanceId': instanceId,
        'domain': domain,
        'workflowName': workflowName,
        if (flowVersion != null && flowVersion!.isNotEmpty) 'flowVersion': flowVersion,
      };

  factory VNextContext.fromJson(Map<String, dynamic> json) => VNextContext(
        instanceId: (json['instanceId'] as String?) ?? '',
        domain: (json['domain'] as String?) ?? 'core',
        workflowName: (json['workflowName'] as String?) ?? '',
        flowVersion: json['flowVersion'] as String?,
      );
}

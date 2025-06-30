/*
 * neo_core
 *
 * Created on 18/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/network/models/http_active_host.dart';

part 'http_host_details.g.dart';

@JsonSerializable(createToJson: false)
class HttpHostDetails {
  @JsonKey(name: 'key', defaultValue: "")
  final String key;

  @JsonKey(name: 'workflow-hub-url', defaultValue: "")
  final String workflowHubUrl;

  @JsonKey(name: 'active-hosts', defaultValue: [])
  final List<HttpActiveHost> activeHosts;

  const HttpHostDetails({
    required this.key,
    required this.workflowHubUrl,
    required this.activeHosts,
  });

  factory HttpHostDetails.fromJson(Map<String, dynamic> json) => _$HttpHostDetailsFromJson(json);
}

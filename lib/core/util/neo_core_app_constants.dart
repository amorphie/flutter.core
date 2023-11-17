/*
 * neo_core
 *
 * Created on 17/11/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:equatable/equatable.dart';

class NeoCoreAppConstants extends Equatable {
  final String workflowHubUrl;
  final String workflowMethodName;

  const NeoCoreAppConstants({required this.workflowHubUrl, required this.workflowMethodName});

  @override
  List<Object?> get props => [workflowHubUrl, workflowMethodName];
}

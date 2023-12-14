/*
 * neo_core
 *
 * Created on 14/12/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';

class SignalrTransitionData {
  final String navigationPath;
  final NeoNavigationType navigationType;
  final String pageId;
  final Map<String, dynamic> initialData;

  SignalrTransitionData({
    required this.navigationPath,
    required this.navigationType,
    required this.pageId,
    required this.initialData,
  });
}

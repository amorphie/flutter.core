/*
 * neo_core
 *
 * Created on 24/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:neo_core/core/network/models/neo_error.dart';

class NeoException implements Exception {
  final NeoError error;

  NeoException({required this.error});

  @override
  String toString() => error.toString();
}

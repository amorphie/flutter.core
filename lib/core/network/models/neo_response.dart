/*
 * neo_core
 *
 * Created on 23/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:neo_core/core/network/models/neo_error.dart';

sealed class NeoResponse {
  const NeoResponse();

  bool get isSuccess {
    return switch (this) {
      NeoErrorResponse(error: final _) => false,
      NeoSuccessResponse(data: final _) => true,
    };
  }

  bool get isError => !isSuccess;

  factory NeoResponse.success(Map<String, dynamic> response) => NeoSuccessResponse(response);

  factory NeoResponse.error(NeoError response) => NeoErrorResponse(response);
}

final class NeoSuccessResponse extends NeoResponse {
  const NeoSuccessResponse(this.data);

  final Map<String, dynamic> data;
}

final class NeoErrorResponse extends NeoResponse {
  const NeoErrorResponse(this.error);

  final NeoError error;
}

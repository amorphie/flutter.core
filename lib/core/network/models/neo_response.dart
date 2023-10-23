/*
 * burgan_core
 *
 * Created on 23/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:burgan_core/core/network/models/brg_error.dart';

sealed class NeoResponse<T> {
  const NeoResponse();

  bool get isSuccess {
    return switch (this) {
      NeoError(error: final _) => false,
      NeoSuccess(data: final _) => true,
    };
  }

  bool get isError => !isSuccess;

  factory NeoResponse.success(T response) => NeoSuccess(response);

  factory NeoResponse.error(BrgError response) => NeoError(response);
}

final class NeoSuccess<T> extends NeoResponse<T> {
  const NeoSuccess(this.data);

  final T data;
}

final class NeoError<T> extends NeoResponse<T> {
  const NeoError(this.error);

  final BrgError error;
}

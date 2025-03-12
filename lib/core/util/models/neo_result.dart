import 'package:neo_core/core/network/models/neo_error.dart';

sealed class NeoResult<T> {
  const NeoResult();

  bool get isSuccess {
    return switch (this) {
      NeoSuccessResult _ => true,
      NeoErrorResult _ => false,
    };
  }

  bool get isError => !isSuccess;

  NeoSuccessResult<T> get asSuccess {
    return this as NeoSuccessResult<T>;
  }

  NeoErrorResult get asError {
    return this as NeoErrorResult;
  }

  factory NeoResult.success(T data) => NeoSuccessResult(data);

  factory NeoResult.error(NeoError error) => NeoErrorResult(error);
}

final class NeoSuccessResult<T> extends NeoResult<T> {
  const NeoSuccessResult(this.data);

  final T data;
}

final class NeoErrorResult<T> extends NeoResult<T> {
  const NeoErrorResult(this.error);

  final NeoError error;
}

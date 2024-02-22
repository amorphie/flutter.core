/*
 * neo_core
 *
 * Created on 22/2/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

part of 'neo_parallel_request_processor_bloc.dart';

sealed class NeoParallelRequestProcessorEvent extends Equatable {
  const NeoParallelRequestProcessorEvent();
}

class NeoParallelRequestProcessorEventInit extends NeoParallelRequestProcessorEvent {
  final List<String> requestIds;

  const NeoParallelRequestProcessorEventInit({required this.requestIds});

  @override
  List<Object?> get props => [requestIds];
}

class NeoParallelRequestProcessorEventCompleteProcessWithSuccess extends NeoParallelRequestProcessorEvent {
  final String requestId;

  const NeoParallelRequestProcessorEventCompleteProcessWithSuccess({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

class NeoParallelRequestProcessorEventCompleteProcessWithError extends NeoParallelRequestProcessorEvent {
  final String requestId;
  final NeoError neoError;

  const NeoParallelRequestProcessorEventCompleteProcessWithError({required this.requestId, required this.neoError});

  @override
  List<Object?> get props => [requestId, neoError];
}

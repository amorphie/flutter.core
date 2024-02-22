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

sealed class NeoParallelRequestProcessorState extends Equatable {
  const NeoParallelRequestProcessorState();
}

class NeoParallelRequestProcessorStateLoading extends NeoParallelRequestProcessorState {
  @override
  List<Object> get props => [];
}

class NeoParallelRequestProcessorStateSuccess extends NeoParallelRequestProcessorState {
  @override
  List<Object> get props => [];
}

class NeoParallelRequestProcessorStateError extends NeoParallelRequestProcessorState {
  final NeoError neoError;

  const NeoParallelRequestProcessorStateError(this.neoError);

  @override
  List<Object> get props => [neoError];
}

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

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:neo_core/core/network/models/neo_error.dart';

part 'neo_parallel_request_processor_event.dart';
part 'neo_parallel_request_processor_state.dart';

class NeoParallelRequestProcessorBloc extends Bloc<NeoParallelRequestProcessorEvent, NeoParallelRequestProcessorState> {
  late List<String> requestIds;

  NeoParallelRequestProcessorBloc() : super(NeoParallelRequestProcessorStateLoading()) {
    on<NeoParallelRequestProcessorEventInit>((event, emit) {
      requestIds = event.requestIds;
    });

    on<NeoParallelRequestProcessorEventCompleteProcessWithSuccess>((event, emit) {
      requestIds.remove(event.requestId);
      if (requestIds.isEmpty) {
        emit(NeoParallelRequestProcessorStateSuccess());
      }
    });

    on<NeoParallelRequestProcessorEventCompleteProcessWithError>((event, emit) {
      emit(NeoParallelRequestProcessorStateError(event.neoError));
    });
  }
}

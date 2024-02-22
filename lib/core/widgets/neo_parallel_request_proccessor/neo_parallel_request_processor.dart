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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neo_core/core/network/models/neo_error.dart';
import 'package:neo_core/core/widgets/neo_parallel_request_proccessor/bloc/neo_parallel_request_processor_bloc.dart';

class NeoParallelRequestProcessor extends StatelessWidget {
  final List<String> requestIds;
  final Widget child;
  final Widget loadingWidget;
  final Widget Function(NeoError error) errorWidgetBuilder;

  const NeoParallelRequestProcessor({
    required this.requestIds,
    required this.child,
    required this.loadingWidget,
    required this.errorWidgetBuilder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          NeoParallelRequestProcessorBloc()..add(NeoParallelRequestProcessorEventInit(requestIds: requestIds)),
      child: BlocBuilder<NeoParallelRequestProcessorBloc, NeoParallelRequestProcessorState>(
        builder: (context, state) {
          switch (state) {
            case NeoParallelRequestProcessorStateLoading _:
              return loadingWidget;

            case NeoParallelRequestProcessorStateSuccess _:
              return child;

            case NeoParallelRequestProcessorStateError _:
              return errorWidgetBuilder(state.neoError);
          }
        },
      ),
    );
  }
}

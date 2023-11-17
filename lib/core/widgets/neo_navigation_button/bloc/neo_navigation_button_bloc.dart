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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';

part 'neo_navigation_button_event.dart';
part 'neo_navigation_button_state.dart';

class NeoNavigationButtonBloc extends Bloc<NeoNavigationButtonEvent, NeoNavigationButtonState> {
  late NeoWorkflowManager neoWorkflowManager;

  NeoNavigationButtonBloc() : super(NeoNavigationButtonInitial()) {
    on<NeoNavigationButtonEventInit>(
      (event, emit) {
        neoWorkflowManager = event.neoWorkflowManager;
        if (event.startWorkflow) {
          neoWorkflowManager.startWorkflow();
        }
      },
    );
  }
}

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

part of 'neo_navigation_button_bloc.dart';

sealed class NeoNavigationButtonEvent extends Equatable {
  const NeoNavigationButtonEvent();
}

class NeoNavigationButtonEventInit extends NeoNavigationButtonEvent {
  final NeoWorkflowManager neoWorkflowManager;
  final bool startWorkflow;

  const NeoNavigationButtonEventInit({required this.neoWorkflowManager, required this.startWorkflow});

  @override
  List<Object?> get props => [neoWorkflowManager, startWorkflow];
}

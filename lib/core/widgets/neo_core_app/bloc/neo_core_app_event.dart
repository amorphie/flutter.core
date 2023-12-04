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

part of 'neo_core_app_bloc.dart';

sealed class NeoCoreAppEvent extends Equatable {
  const NeoCoreAppEvent();
}

class NeoCoreAppEventInitConfigurations extends NeoCoreAppEvent {
  final NeoCoreAppConstants appConstants;
  final INeoNavigationHelper neoNavigationHelper;
  final FirebaseOptions firebaseOptions;

  const NeoCoreAppEventInitConfigurations({
    required this.appConstants,
    required this.neoNavigationHelper,
    required this.firebaseOptions,
  });

  @override
  List<Object?> get props => [appConstants, neoNavigationHelper, firebaseOptions];
}

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

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:neo_core/core/navigation/i_neo_navigation_helper.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/util/neo_core_app_constants.dart';

part 'neo_core_app_event.dart';
part 'neo_core_app_state.dart';

class NeoCoreAppBloc extends Bloc<NeoCoreAppEvent, NeoCoreAppState> {
  late NeoNetworkManager neoNetworkManager;
  late NeoCoreAppConstants neoCoreAppConstants;
  late INeoNavigationHelper neoNavigationHelper;

  NeoCoreAppBloc() : super(NeoCoreAppInitial()) {
    on<NeoCoreAppEventInitConfigurations>((event, emit) {
      neoNetworkManager = event.neoNetworkManager;
      neoCoreAppConstants = event.appConstants;
      neoNavigationHelper = event.neoNavigationHelper;
    });
  }
}

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
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/navigation/i_neo_navigation_helper.dart';
import 'package:neo_core/core/util/neo_core_app_constants.dart';

part 'neo_core_app_event.dart';
part 'neo_core_app_state.dart';

class NeoCoreAppBloc extends Bloc<NeoCoreAppEvent, NeoCoreAppState> {
  NeoCoreAppBloc() : super(NeoCoreAppInitial()) {
    on<NeoCoreAppEventInitConfigurations>((event, emit) {
      GetIt.I.registerSingleton<NeoCoreAppConstants>(event.appConstants);
      GetIt.I.registerSingleton<INeoNavigationHelper>(event.neoNavigationHelper);
    });
  }
}

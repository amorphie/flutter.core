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
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/navigation/i_neo_navigation_helper.dart';
import 'package:neo_core/core/util/neo_core_app_constants.dart';
import 'package:neo_core/core/util/neo_crashlytics.dart';

part 'neo_core_app_event.dart';
part 'neo_core_app_state.dart';

class NeoCoreAppBloc extends Bloc<NeoCoreAppEvent, NeoCoreAppState> {
  NeoCoreAppBloc() : super(NeoCoreAppInitial()) {
    on<NeoCoreAppEventInitConfigurations>((event, emit) {
      GetIt.I.registerSingleton<NeoCoreAppConstants>(event.appConstants);
      GetIt.I.registerSingleton<INeoNavigationHelper>(event.neoNavigationHelper);
      if (!kIsWeb) {
        _initFirebase();
      }
    });
  }

  _initFirebase() async {
    await Firebase.initializeApp();
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    await NeoCrashlytics.sendUnsentReports();
  }
}

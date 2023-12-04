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

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neo_core/core/navigation/i_neo_navigation_helper.dart';
import 'package:neo_core/core/util/neo_core_app_constants.dart';
import 'package:neo_core/core/widgets/neo_core_app/bloc/neo_core_app_bloc.dart';

class NeoCoreApp extends StatelessWidget {
  final Widget child;
  final NeoCoreAppConstants appConstants;
  final INeoNavigationHelper neoNavigationHelper;
  final FirebaseOptions firebaseOptions;

  const NeoCoreApp({
    required this.child,
    required this.appConstants,
    required this.neoNavigationHelper,
    required this.firebaseOptions,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NeoCoreAppBloc()
        ..add(
          NeoCoreAppEventInitConfigurations(
            appConstants: appConstants,
            neoNavigationHelper: neoNavigationHelper,
          ),
        ),
      child: BlocBuilder<NeoCoreAppBloc, NeoCoreAppState>(
        builder: (context, state) {
          return child;
        },
      ),
    );
  }
}

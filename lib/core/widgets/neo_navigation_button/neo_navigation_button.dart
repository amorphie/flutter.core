import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/navigation/i_neo_navigation_helper.dart';
import 'package:neo_core/core/navigation/neo_navigation_type.dart';
import 'package:neo_core/core/widgets/neo_navigation_button/bloc/neo_navigation_button_bloc.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:neo_core/neo_core.dart';

const _buttonColor = Color(0xFF0069AA); // TODO: Get style from constructor params

class NeoNavigationButton extends StatelessWidget {
  const NeoNavigationButton({
    required this.text,
    required this.navigationPath,
    this.paddingAll = 16,
    this.startWorkflow = false,
    Key? key,
  }) : super(key: key);

  final String text;
  final String navigationPath;
  final double paddingAll;
  final bool startWorkflow;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NeoNavigationButtonBloc()
        ..add(
          NeoNavigationButtonEventInit(
            neoWorkflowManager: NeoWorkflowManager(GetIt.I<NeoNetworkManager>()),
            startWorkflow: startWorkflow,
          ),
        ),
      child: BlocBuilder<NeoNavigationButtonBloc, NeoNavigationButtonState>(
        builder: (context, state) {
          return FilledButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: _buttonColor,
            ),
            onPressed: () => _handleNavigation(context),
            child: Text(text).padding(left: 16, right: 16, top: 20, bottom: 20),
          );
        },
      ),
    ).paddingAll(paddingAll);
  }

  void _handleNavigation(BuildContext context) {
    GetIt.I<INeoNavigationHelper>().navigate(
      context: context,
      // STOPSHIP: Get navigation type from signalR
      navigationType: NeoNavigationType.pushReplacement,
      navigationPath: navigationPath,
    );
  }
}

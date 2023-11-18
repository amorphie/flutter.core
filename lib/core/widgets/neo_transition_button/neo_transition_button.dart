import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neo_core/core/navigation/neo_navigation_type.dart';
import 'package:neo_core/core/widgets/neo_core_app/bloc/neo_core_app_bloc.dart';
import 'package:neo_core/core/workflow_form/bloc/workflow_form_bloc.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:neo_core/neo_core.dart';

const _buttonColor = Color(0xFF0069AA); // TODO: Move to colors file

class NeoTransitionButton extends StatefulWidget {
  const NeoTransitionButton({
    required this.entity,
    required this.transitionId,
    required this.text,
    Key? key,
  }) : super(key: key);

  final String entity;
  final String transitionId;
  final String text;

  @override
  State<NeoTransitionButton> createState() => _NeoTransitionButtonState();
}

class _NeoTransitionButtonState extends State<NeoTransitionButton> {
  @override
  Widget build(BuildContext context) {
    final appBloc = context.read<NeoCoreAppBloc>();
    return NeoTransitionListenerWidget(
      transitionId: widget.transitionId,
      signalRServerUrl: appBloc.neoCoreAppConstants.workflowHubUrl,
      signalRMethodName: appBloc.neoCoreAppConstants.workflowMethodName,
      onPageNavigation: (String navigationPath) => _handleNavigation(context, navigationPath),
      child: FilledButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: _buttonColor,
        ),
        onPressed: () {
          final appBloc = context.read<NeoCoreAppBloc>();
          NeoWorkflowManager(appBloc.neoNetworkManager).postTransition(
            entity: widget.entity,
            transitionId: widget.transitionId,
            body: _getFormParametersIfExist(context),
          );
        },
        child: Text(widget.text).padding(left: 16, right: 16, top: 20, bottom: 20),
      ),
    );
  }

  Map<String, dynamic> _getFormParametersIfExist(BuildContext context) {
    Map<String, dynamic> data = {};
    try {
      data = context.read<WorkflowFormBloc>().formData;
    } on Exception catch (_) {
      // no-op
    }
    return data;
  }

  void _handleNavigation(BuildContext context, String navigationPath) {
    context.read<NeoCoreAppBloc>().neoNavigationHelper.navigate(
          context: context,
          // STOPSHIP: Get navigation type from signalR
          navigationType: NeoNavigationType.pushReplacement,
          navigationPath: navigationPath,
        );
  }
}

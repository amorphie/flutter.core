import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:neo_core/core/navigation/i_neo_navigation_helper.dart';
import 'package:neo_core/core/navigation/neo_navigation_type.dart';
import 'package:neo_core/core/util/neo_core_app_constants.dart';
import 'package:neo_core/core/workflow_form/bloc/workflow_form_bloc.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:neo_core/neo_core.dart';

abstract class INeoTransitionButton extends StatelessWidget {
  const INeoTransitionButton({
    required this.entity,
    required this.transitionId,
    Key? key,
  }) : super(key: key);

  final String entity;
  final String transitionId;

  abstract final Widget Function(BuildContext) childBuilder;

  @nonVirtual
  @override
  Widget build(BuildContext context) {
    final appConstants = GetIt.I<NeoCoreAppConstants>();
    return NeoTransitionListenerWidget(
      transitionId: transitionId,
      signalRServerUrl: appConstants.workflowHubUrl,
      signalRMethodName: appConstants.workflowMethodName,
      onPageNavigation: (String navigationPath) => _handleNavigation(context, navigationPath),
      onError: (errorMessage) => onTransitionError(context, errorMessage),
      child: childBuilder(context),
    );
  }

  /// Triggered when there is an error from SignalR
  @visibleForOverriding
  void onTransitionError(BuildContext context, String errorMessage);

  Future onStartTransition(BuildContext context) {
    return NeoWorkflowManager(GetIt.I<NeoNetworkManager>()).postTransition(
      entity: entity,
      transitionId: transitionId,
      body: _getFormParametersIfExist(context),
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
    GetIt.I<INeoNavigationHelper>().navigate(
      context: context,
      // STOPSHIP: Get navigation type from signalR
      navigationType: NeoNavigationType.pushReplacement,
      navigationPath: navigationPath,
    );
  }
}

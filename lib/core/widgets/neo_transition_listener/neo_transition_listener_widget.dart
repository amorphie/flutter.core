import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/bloc/neo_transition_listener_bloc.dart';

class NeoTransitionListenerWidget extends StatelessWidget {
  final Widget child;
  final String signalRServerUrl;
  final String signalRMethodName;
  final Function(SignalrTransitionData navigationData) onPageNavigation;
  final VoidCallback? onLoggedInSuccessfully;
  final Function(String errorMessage)? onError;

  const NeoTransitionListenerWidget({
    required this.child,
    required this.signalRServerUrl,
    required this.signalRMethodName,
    required this.onPageNavigation,
    this.onLoggedInSuccessfully,
    this.onError,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NeoTransitionListenerBloc()
        ..add(NeoTransitionListenerEventInit(
          signalRServerUrl: signalRServerUrl,
          signalRMethodName: signalRMethodName,
          onPageNavigation: onPageNavigation,
          onLoggedInSuccessfully: onLoggedInSuccessfully,
          onError: onError,
        )),
      child: BlocBuilder<NeoTransitionListenerBloc, NeoTransitionListenerState>(
        builder: (context, state) {
          return child;
        },
      ),
    );
  }
}

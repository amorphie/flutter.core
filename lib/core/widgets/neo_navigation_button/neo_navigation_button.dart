import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neo_core/core/navigation/neo_navigation_type.dart';
import 'package:neo_core/core/widgets/neo_core_app/bloc/neo_core_app_bloc.dart';
import 'package:neo_core/neo_core.dart';

const _buttonColor = Color(0xFF0069AA); // TODO: Get style from constructor params

class NeoNavigationButton extends StatelessWidget {
  const NeoNavigationButton({
    required this.text,
    required this.navigationPath,
    this.paddingAll = 16,
    Key? key,
  }) : super(key: key);

  final String text;
  final String navigationPath;
  final double paddingAll;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: _buttonColor,
      ),
      onPressed: () => _handleNavigation(context),
      child: Text(text).padding(left: 16, right: 16, top: 20, bottom: 20),
    ).paddingAll(paddingAll);
  }

  void _handleNavigation(BuildContext context) {
    context.read<NeoCoreAppBloc>().neoNavigationHelper.navigate(
          context: context,
          // STOPSHIP: Get navigation type from signalR
          navigationType: NeoNavigationType.pushReplacement,
          navigationPath: navigationPath,
        );
  }
}

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:neo_core/core/widgets/neo_transition_button/i_neo_transition_button.dart';
import 'package:neo_core/neo_core.dart';

const _buttonColor = Color(0xFF0069AA); // TODO: Move to colors file

class NeoTransitionButton extends INeoTransitionButton {
  const NeoTransitionButton({
    required super.entity,
    required super.transitionId,
    required super.text,
    super.key,
  });

  /// Don't forget to call [onStartTransition] to start transition
  @override
  @visibleForOverriding
  Widget buildCustom(BuildContext context) {
    return FilledButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: _buttonColor,
      ),
      onPressed: () => onStartTransition(context),
      child: Text(text).padding(left: 16, right: 16, top: 20, bottom: 20),
    );
  }

  @override
  void onTransitionError(String errorMessage) {
    // No-op. Override if necessary
  }
}

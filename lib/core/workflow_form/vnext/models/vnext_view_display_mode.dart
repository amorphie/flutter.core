/*
 * neo_core
 *
 * VNext View Display Mode: Enum for view rendering modes
 */

import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';

/// Display modes for vNext views as defined in the vNext runtime documentation.
///
/// These modes determine how a view is presented to the user:
/// - [fullPage]: Full-screen component (default for main workflow screens)
/// - [popup]: Modal/popup dialog overlaying the current screen
/// - [bottomSheet]: Bottom sheet sliding up from the bottom
/// - [topSheet]: Top sheet sliding down from the top
/// - [drawer]: Side drawer/menu sliding in from the side
/// - [inline]: Inline within the current page content
enum VNextViewDisplayMode {
  /// Renders the view as a full-page component, taking up the entire screen.
  /// Use cases: Main workflow screens, complex forms, dashboard views
  fullPage('full-page'),

  /// Renders the view as a modal/popup dialog overlaying the current screen.
  /// Use cases: Confirmation dialogs, alert messages, short forms
  popup('popup'),

  /// Renders the view as a bottom sheet sliding up from the bottom of the screen.
  /// Use cases: Mobile-friendly selections, quick actions, filter options
  bottomSheet('bottom-sheet'),

  /// Renders the view as a top sheet sliding down from the top of the screen.
  /// Use cases: Notifications, success messages, quick information display
  topSheet('top-sheet'),

  /// Renders the view as a side drawer/menu sliding in from the side.
  /// Use cases: Navigation menus, settings panels, side filters
  drawer('drawer'),

  /// Renders the view inline within the current page content.
  /// Use cases: Embedded forms, inline editors, contextual information
  inline('inline');

  const VNextViewDisplayMode(this.value);

  /// The string value as returned from the backend API
  final String value;

  /// Creates a [VNextViewDisplayMode] from a string value.
  /// Returns [fullPage] as default if the value is null, empty, or unrecognized.
  static VNextViewDisplayMode fromString(String? value) {
    if (value == null || value.isEmpty) {
      return VNextViewDisplayMode.fullPage;
    }

    return VNextViewDisplayMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => VNextViewDisplayMode.fullPage,
    );
  }

  /// Converts the enum to its string representation for JSON serialization.
  String toJson() => value;

  NeoNavigationType toNavigationType() {
    switch (this) {
      case VNextViewDisplayMode.fullPage:
        return NeoNavigationType.pushReplacement;
      case VNextViewDisplayMode.popup:
        return NeoNavigationType.popup;
      case VNextViewDisplayMode.bottomSheet:
        return NeoNavigationType.bottomSheet;

      // TODO: Handle these cases.
      case VNextViewDisplayMode.topSheet:
      case VNextViewDisplayMode.drawer:
      case VNextViewDisplayMode.inline:
        return NeoNavigationType.pushReplacement;
    }
  }
}

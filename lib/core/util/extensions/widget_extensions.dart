import 'package:flutter/widgets.dart';

extension WidgetExtensions on Widget {
  Widget paddingAll(double value) {
    return Padding(padding: EdgeInsets.all(value), child: this);
  }

  Widget paddingHorizontal(double value) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: value), child: this);
  }

  Widget paddingVertical(double value) {
    return Padding(padding: EdgeInsets.symmetric(vertical: value), child: this);
  }

  Widget padding({double left = 0.0, double top = 0.0, double right = 0.0, double bottom = 0.0}) {
    return Padding(
      padding: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom),
      child: this,
    );
  }
}

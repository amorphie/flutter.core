import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum NeoNavigationType {
  @JsonValue('pop-until')
  popUntil('pop-until'),

  @JsonValue('push')
  push('push'),

  @JsonValue('push-replacement')
  pushReplacement('push-replacement'),

  @JsonValue('push-as-root')
  pushAsRoot('push-as-root'),

  @JsonValue('popup')
  popup('popup'),

  @JsonValue('bottom-sheet')
  bottomSheet('bottom-sheet');

  final String value;

  const NeoNavigationType(this.value);
}

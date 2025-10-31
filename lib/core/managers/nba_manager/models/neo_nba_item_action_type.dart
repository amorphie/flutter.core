import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum NeoNbaItemActionType {
  @JsonValue(0)
  noAction(0),
  @JsonValue(1)
  externalLink(1),
  @JsonValue(2)
  deeplink(2),
  ;

  final int value;

  const NeoNbaItemActionType(this.value);
}

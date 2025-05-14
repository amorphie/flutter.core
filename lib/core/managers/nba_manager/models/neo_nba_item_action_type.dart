import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum NeoNbaItemActionType {
  @JsonValue(0)
  noAction,
  @JsonValue(1)
  externalLink,
  @JsonValue(2)
  deeplink,
  ;
}

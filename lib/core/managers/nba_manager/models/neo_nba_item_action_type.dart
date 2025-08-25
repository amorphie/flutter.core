import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum NeoNbaItemActionType {
  @JsonValue(0)
  noAction('noAction'),
  @JsonValue(1)
  externalLink('externalLink'),
  @JsonValue(2)
  deeplink('deeplink'),
  ;

  final String value;

  const NeoNbaItemActionType(this.value);
}

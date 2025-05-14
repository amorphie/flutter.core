import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum NeoNbaItemType {
  @JsonValue(1)
  inApp,
  @JsonValue(2)
  placeholder,
  @JsonValue(3)
  mail,
  @JsonValue(4)
  sms,
  @JsonValue(5)
  push,
  @JsonValue(6)
  ivn,
  @JsonValue(7)
  serviceCall,
  @JsonValue(8)
  card,
  ;
}

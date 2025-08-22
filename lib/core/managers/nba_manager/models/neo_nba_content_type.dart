import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum NeoNbaContentType {
  @JsonValue(4)
  image,
  @JsonValue(5)
  dynamicWidget,
  ;

  static NeoNbaContentType fromJson(String value) {
    switch (value) {
      case 'image':
        return NeoNbaContentType.image;
      case 'dynamicWidget':
        return NeoNbaContentType.dynamicWidget;
      default:
        throw ArgumentError('Unsupported enum value: $value');
    }
  }
}

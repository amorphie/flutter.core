import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum NeoNbaContentType {
  @JsonValue(4)
  image('image'),
  @JsonValue(5)
  dynamicWidget('dynamicWidget'),
  ;

  final String value;

  const NeoNbaContentType(this.value);

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

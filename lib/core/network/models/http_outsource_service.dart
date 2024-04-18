import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/network/models/http_method.dart';

part 'http_outsource_service.g.dart';

@JsonSerializable(createToJson: false)
class HttpOutsourceService {
  const HttpOutsourceService({
    required this.key,
    required this.method,
    required this.url,
  });

  factory HttpOutsourceService.fromJson(Map<String, dynamic> json) => _$HttpOutsourceServiceFromJson(json);
  
  @JsonKey(name: "key", defaultValue: "")
  final String key;

  @JsonKey(name: "method", defaultValue: HttpMethod.get)
  final HttpMethod method;

  @JsonKey(name: "url", defaultValue: "")
  final String url;
}

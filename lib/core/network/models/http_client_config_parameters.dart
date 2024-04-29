import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';

part 'http_client_config_parameters.g.dart';

@JsonSerializable(createToJson: false)
class HttpClientConfigParameters {
  const HttpClientConfigParameters({
    required this.cachePages,
    required this.cacheStorage,
    required this.logLevel,
  });

  @JsonKey(name: 'cache-pages', defaultValue: false)
  final bool cachePages;

  @JsonKey(name: 'cache-storage', defaultValue: false)
  final bool cacheStorage;

  @JsonKey(name: 'log-level', fromJson: _logLevelFromJson, defaultValue: Level.off)
  final Level logLevel;

  static Level _logLevelFromJson(String value) {
    return Level.values.firstWhere((level) => level.name == value, orElse: () => Level.off);
  }

  factory HttpClientConfigParameters.fromJson(Map<String, dynamic> json) => _$HttpClientConfigParametersFromJson(json);
}

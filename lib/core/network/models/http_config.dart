import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';

part 'http_config.g.dart';

@JsonSerializable(createToJson: false)
class HttpConfig {
  const HttpConfig({
    required this.cachePages,
    required this.logLevel,
  });

  @JsonKey(name: 'cache-pages', defaultValue: false)
  final bool cachePages;

  @JsonKey(name: 'log-level', fromJson: _logLevelFromJson, defaultValue: Level.off)
  final Level logLevel;

  static Level _logLevelFromJson(String value) {
    return Level.values.firstWhere((level) => level.name == value, orElse: () => Level.off);
  }

  factory HttpConfig.fromJson(Map<String, dynamic> json) => _$HttpConfigFromJson(json);
}

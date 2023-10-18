// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_host_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HttpHostDetails _$HttpHostDetailsFromJson(Map<String, dynamic> json) =>
    HttpHostDetails(
      key: json['key'] as String? ?? '',
      oauthClient: json['oauth-client'] as String? ?? '',
      oauthServer: json['oauth-server'] as String? ?? '',
      activeHosts: (json['active-hosts'] as List<dynamic>?)
              ?.map((e) => HttpActiveHost.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

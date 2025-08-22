// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_navigation_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoNavigationEventModel _$NeoNavigationEventModelFromJson(
        Map<String, dynamic> json) =>
    NeoNavigationEventModel(
      navigationPath: json['navigationPath'] as String?,
      popArguments: json['popArguments'],
      useRootNavigator: json['useRootNavigator'] as bool? ?? false,
    );

Map<String, dynamic> _$NeoNavigationEventModelToJson(
        NeoNavigationEventModel instance) =>
    <String, dynamic>{
      'navigationPath': instance.navigationPath,
      'popArguments': instance.popArguments,
      'useRootNavigator': instance.useRootNavigator,
    };

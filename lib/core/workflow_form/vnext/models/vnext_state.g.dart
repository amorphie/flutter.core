// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vnext_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VNextState _$VNextStateFromJson(Map<String, dynamic> json) => VNextState(
      data: json['data'] as Map<String, dynamic>,
      view: json['view'] as Map<String, dynamic>,
      state: json['state'] as String,
      transitions: (json['transitions'] as List<dynamic>)
          .map((e) => VNextTransition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$VNextStateToJson(VNextState instance) =>
    <String, dynamic>{
      'data': instance.data,
      'view': instance.view,
      'state': instance.state,
      'transitions': instance.transitions,
    };

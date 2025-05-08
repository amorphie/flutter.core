import 'package:json_annotation/json_annotation.dart';

part 'neo_navigation_event_model.g.dart';

@JsonSerializable()
class NeoNavigationEventModel {
  final String? navigationPath;

  /// This parameter can be used to return an object from page when popped
  final dynamic popArguments;

  /// This function can be used after pushing a page to retrieve a result when page is popped
  @JsonKey(
    includeFromJson: false,
    includeToJson: false,
  ) // Consider to use JsonDynamicWidget for deserialize the function
  final Function(dynamic popArguments)? onPopped;

  /// This parameter is used to determine if the navigation should be done using the root navigator or not
  final bool useRootNavigator;

  NeoNavigationEventModel({this.navigationPath, this.popArguments, this.onPopped, this.useRootNavigator = false});

  factory NeoNavigationEventModel.fromJson(Map<String, dynamic> json) => _$NeoNavigationEventModelFromJson(json);
  Map<String, dynamic> toJson() => _$NeoNavigationEventModelToJson(this);
}

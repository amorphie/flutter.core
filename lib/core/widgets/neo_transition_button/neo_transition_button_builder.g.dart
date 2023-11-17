// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_transition_button_builder.dart';

// **************************************************************************
// Generator: JsonWidgetLibraryBuilder
// **************************************************************************

// ignore_for_file: deprecated_member_use

// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_constructors_in_immutables
// ignore_for_file: prefer_final_locals
// ignore_for_file: prefer_single_quotes
// ignore_for_file: unused_local_variable

class NeoTransitionButtonBuilder extends _NeoTransitionButtonBuilder {
  const NeoTransitionButtonBuilder({required super.args});

  static const kType = 'neo_transition_button';

  /// Constant that can be referenced for the builder's type.
  @override
  String get type => kType;

  /// Static function that is capable of decoding the widget from a dynamic JSON
  /// or YAML set of values.
  static NeoTransitionButtonBuilder fromDynamic(
    dynamic map, {
    JsonWidgetRegistry? registry,
  }) =>
      NeoTransitionButtonBuilder(
        args: map,
      );
  @override
  NeoTransitionButtonBuilderModel createModel({
    ChildWidgetBuilder? childBuilder,
    required JsonWidgetData data,
  }) {
    final model = NeoTransitionButtonBuilderModel.fromDynamic(
      args,
      registry: data.jsonWidgetRegistry,
    );

    return model;
  }

  @override
  NeoTransitionButton buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  }) {
    final model = createModel(
      childBuilder: childBuilder,
      data: data,
    );

    return NeoTransitionButton(
      entity: model.entity,
      key: key,
      text: model.text,
      transitionId: model.transitionId,
    );
  }
}

class JsonNeoTransitionButton extends JsonWidgetData {
  JsonNeoTransitionButton({
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
    required this.entity,
    required this.text,
    required this.transitionId,
  }) : super(
          jsonWidgetArgs: NeoTransitionButtonBuilderModel.fromDynamic(
            {
              'entity': entity,
              'text': text,
              'transitionId': transitionId,
              ...args,
            },
            args: args,
            registry: registry,
          ),
          jsonWidgetBuilder: () => NeoTransitionButtonBuilder(
            args: NeoTransitionButtonBuilderModel.fromDynamic(
              {
                'entity': entity,
                'text': text,
                'transitionId': transitionId,
                ...args,
              },
              args: args,
              registry: registry,
            ),
          ),
          jsonWidgetType: NeoTransitionButtonBuilder.kType,
        );

  final String entity;

  final String text;

  final String transitionId;
}

class NeoTransitionButtonBuilderModel extends JsonWidgetBuilderModel {
  const NeoTransitionButtonBuilderModel(
    super.args, {
    required this.entity,
    required this.text,
    required this.transitionId,
  });

  final String entity;

  final String text;

  final String transitionId;

  static NeoTransitionButtonBuilderModel fromDynamic(
    dynamic map, {
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
  }) {
    final result = maybeFromDynamic(
      map,
      args: args,
      registry: registry,
    );

    if (result == null) {
      throw Exception(
        '[NeoTransitionButtonBuilder]: requested to parse from dynamic, but the input is null.',
      );
    }

    return result;
  }

  static NeoTransitionButtonBuilderModel? maybeFromDynamic(
    dynamic map, {
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
  }) {
    NeoTransitionButtonBuilderModel? result;

    if (map != null) {
      if (map is String) {
        map = yaon.parse(
          map,
          normalize: true,
        );
      }

      if (map is NeoTransitionButtonBuilderModel) {
        result = map;
      } else {
        registry ??= JsonWidgetRegistry.instance;
        map = registry.processArgs(map, <String>{}).value;
        result = NeoTransitionButtonBuilderModel(
          args,
          entity: map['entity'],
          text: map['text'],
          transitionId: map['transitionId'],
        );
      }
    }

    return result;
  }

  @override
  Map<String, dynamic> toJson() {
    return JsonClass.removeNull({
      'entity': entity,
      'text': text,
      'transitionId': transitionId,
      ...args,
    });
  }
}

class NeoTransitionButtonSchema {
  static const id =
      'https://peiffer-innovations.github.io/flutter_json_schemas/schemas/neo_core/neo_transition_button.json';

  static final schema = <String, Object>{
    r'$schema': 'http://json-schema.org/draft-07/schema#',
    r'$id': id,
    'title': 'NeoTransitionButton',
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'entity': SchemaHelper.stringSchema,
      'text': SchemaHelper.stringSchema,
      'transitionId': SchemaHelper.stringSchema,
    },
  };
}

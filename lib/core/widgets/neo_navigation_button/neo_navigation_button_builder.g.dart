// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_navigation_button_builder.dart';

// **************************************************************************
// Generator: JsonWidgetLibraryBuilder
// **************************************************************************

// ignore_for_file: deprecated_member_use

// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_constructors_in_immutables
// ignore_for_file: prefer_final_locals
// ignore_for_file: prefer_single_quotes
// ignore_for_file: unused_local_variable

class NeoNavigationButtonBuilder extends _NeoNavigationButtonBuilder {
  const NeoNavigationButtonBuilder({required super.args});

  static const kType = 'neo_navigation_button';

  /// Constant that can be referenced for the builder's type.
  @override
  String get type => kType;

  /// Static function that is capable of decoding the widget from a dynamic JSON
  /// or YAML set of values.
  static NeoNavigationButtonBuilder fromDynamic(
    dynamic map, {
    JsonWidgetRegistry? registry,
  }) =>
      NeoNavigationButtonBuilder(
        args: map,
      );
  @override
  NeoNavigationButtonBuilderModel createModel({
    ChildWidgetBuilder? childBuilder,
    required JsonWidgetData data,
  }) {
    final model = NeoNavigationButtonBuilderModel.fromDynamic(
      args,
      registry: data.jsonWidgetRegistry,
    );

    return model;
  }

  @override
  NeoNavigationButton buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  }) {
    final model = createModel(
      childBuilder: childBuilder,
      data: data,
    );

    return NeoNavigationButton(
      key: key,
      navigationPath: model.navigationPath,
      paddingAll: model.paddingAll,
      startWorkflow: model.startWorkflow,
      text: model.text,
    );
  }
}

class JsonNeoNavigationButton extends JsonWidgetData {
  JsonNeoNavigationButton({
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
    required this.navigationPath,
    this.paddingAll = 16,
    this.startWorkflow = false,
    required this.text,
  }) : super(
          jsonWidgetArgs: NeoNavigationButtonBuilderModel.fromDynamic(
            {
              'navigationPath': navigationPath,
              'paddingAll': paddingAll,
              'startWorkflow': startWorkflow,
              'text': text,
              ...args,
            },
            args: args,
            registry: registry,
          ),
          jsonWidgetBuilder: () => NeoNavigationButtonBuilder(
            args: NeoNavigationButtonBuilderModel.fromDynamic(
              {
                'navigationPath': navigationPath,
                'paddingAll': paddingAll,
                'startWorkflow': startWorkflow,
                'text': text,
                ...args,
              },
              args: args,
              registry: registry,
            ),
          ),
          jsonWidgetType: NeoNavigationButtonBuilder.kType,
        );

  final String navigationPath;

  final double paddingAll;

  final bool startWorkflow;

  final String text;
}

class NeoNavigationButtonBuilderModel extends JsonWidgetBuilderModel {
  const NeoNavigationButtonBuilderModel(
    super.args, {
    required this.navigationPath,
    this.paddingAll = 16,
    this.startWorkflow = false,
    required this.text,
  });

  final String navigationPath;

  final double paddingAll;

  final bool startWorkflow;

  final String text;

  static NeoNavigationButtonBuilderModel fromDynamic(
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
        '[NeoNavigationButtonBuilder]: requested to parse from dynamic, but the input is null.',
      );
    }

    return result;
  }

  static NeoNavigationButtonBuilderModel? maybeFromDynamic(
    dynamic map, {
    Map<String, dynamic> args = const {},
    JsonWidgetRegistry? registry,
  }) {
    NeoNavigationButtonBuilderModel? result;

    if (map != null) {
      if (map is String) {
        map = yaon.parse(
          map,
          normalize: true,
        );
      }

      if (map is NeoNavigationButtonBuilderModel) {
        result = map;
      } else {
        registry ??= JsonWidgetRegistry.instance;
        map = registry.processArgs(map, <String>{}).value;
        result = NeoNavigationButtonBuilderModel(
          args,
          navigationPath: map['navigationPath'],
          paddingAll: () {
            dynamic parsed = JsonClass.maybeParseDouble(map['paddingAll']);

            parsed ??= 16.0;

            return parsed;
          }(),
          startWorkflow: JsonClass.parseBool(
            map['startWorkflow'],
            whenNull: false,
          ),
          text: map['text'],
        );
      }
    }

    return result;
  }

  @override
  Map<String, dynamic> toJson() {
    return JsonClass.removeNull({
      'navigationPath': navigationPath,
      'paddingAll': 16 == paddingAll ? null : paddingAll,
      'startWorkflow': false == startWorkflow ? null : startWorkflow,
      'text': text,
      ...args,
    });
  }
}

class NeoNavigationButtonSchema {
  static const id =
      'https://peiffer-innovations.github.io/flutter_json_schemas/schemas/neo_core/neo_navigation_button.json';

  static final schema = <String, Object>{
    r'$schema': 'http://json-schema.org/draft-07/schema#',
    r'$id': id,
    'title': 'NeoNavigationButton',
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'navigationPath': SchemaHelper.stringSchema,
      'paddingAll': SchemaHelper.numberSchema,
      'startWorkflow': SchemaHelper.boolSchema,
      'text': SchemaHelper.stringSchema,
    },
  };
}

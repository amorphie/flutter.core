import 'package:flutter/material.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/neo_core.dart';
import 'package:uuid/uuid.dart';

abstract class _Constants {
  static const endpointGetTransition = "get-transitions";
  static const endpointPostTransition = "post-transition";
  static const pathParameterEntity = "ENTITY";
  static const pathParameterRecordId = "RECORD_ID";
  static const pathParameterTransitionId = "TRANSITION_ID";
}

class NeoWorkflowManager {
  final NeoNetworkManager neoNetworkManager;
  final String recordId = const Uuid().v1();

  NeoWorkflowManager(this.neoNetworkManager);

  Future getTransitions({required String entityId}) async {
    final response = await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointGetTransition,
        pathParameters: {
          _Constants.pathParameterEntity: entityId,
          _Constants.pathParameterRecordId: recordId,
        },
      ),
    );
    debugPrint('[NeoWorkflowManager] Get Transitions: $response');
  }

  Future postTransition({
    required String entity,
    required String recordId,
    required String transitionId,
    required Map<String, dynamic> body,
  }) async {
    await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointPostTransition,
        pathParameters: {
          _Constants.pathParameterEntity: entity,
          _Constants.pathParameterRecordId: recordId,
          _Constants.pathParameterTransitionId: transitionId,
        },
        body: body,
      ),
    );
  }
}

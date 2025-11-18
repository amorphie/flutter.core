import 'package:flutter_test/flutter_test.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_instance_snapshot.dart';

void main() {
  group('VNextInstanceSnapshot', () {
    test('should parse JSON correctly with all fields', () {
      // JSON from the user's example
      final json = {
        "id": "019a0bb3-278a-7622-94b2-cae6d9a7522e",
        "key": "1761132881494",
        "flow": "account-opening",
        "domain": "core",
        "flowVersion": "1.0.0",
        "etag": "01K85V69WMNAQSE1QH33KMGQ03",
        "tags": [],
        "extensions": {
          "data": {
            "href": "core/workflows/account-opening/instances/019a0bb3-278a-7622-94b2-cae6d9a7522e/functions/data?async=false"
          },
          "currentState": "account-type-selection",
          "view": {
            "loadData": true,
            "href": "core/workflows/account-opening/instances/019a0bb3-278a-7622-94b2-cae6d9a7522e/functions/view?async=false"
          },
          "activeCorrelations": [],
          "transitions": [
            {
              "name": "select-demand-deposit",
              "href": "/core/workflows/account-opening/instances/019a0bb3-278a-7622-94b2-cae6d9a7522e/transitions/select-demand-deposit"
            },
            {
              "name": "cancel-account-opening",
              "href": "/core/workflows/account-opening/instances/019a0bb3-278a-7622-94b2-cae6d9a7522e/transitions/cancel-account-opening"
            }
          ],
          "status": "A"
        }
      };

      final snapshot = VNextInstanceSnapshot.fromInstanceJson(json);

      // Test all fields
      expect(snapshot.instanceId, equals("019a0bb3-278a-7622-94b2-cae6d9a7522e"));
      expect(snapshot.key, equals("1761132881494"));
      expect(snapshot.workflowName, equals("account-opening")); // CRITICAL: Should extract from 'flow'
      expect(snapshot.domain, equals("core"));
      expect(snapshot.flowVersion, equals("1.0.0"));
      expect(snapshot.etag, equals("01K85V69WMNAQSE1QH33KMGQ03"));
      expect(snapshot.tags, equals([]));
      expect(snapshot.state, equals("account-type-selection"));
      expect(snapshot.status, equals("A"));
      expect(snapshot.viewHref, equals("core/workflows/account-opening/instances/019a0bb3-278a-7622-94b2-cae6d9a7522e/functions/view?async=false"));
      expect(snapshot.loadData, equals(true));
      expect(snapshot.dataHref, equals("core/workflows/account-opening/instances/019a0bb3-278a-7622-94b2-cae6d9a7522e/functions/data?async=false"));
      expect(snapshot.activeCorrelations, equals([]));
      
      // Test transitions
      expect(snapshot.transitions.length, equals(2));
      expect(snapshot.transitions[0].name, equals("select-demand-deposit"));
      expect(snapshot.transitions[0].href, equals("/core/workflows/account-opening/instances/019a0bb3-278a-7622-94b2-cae6d9a7522e/transitions/select-demand-deposit"));
      expect(snapshot.transitions[1].name, equals("cancel-account-opening"));
      expect(snapshot.transitions[1].href, equals("/core/workflows/account-opening/instances/019a0bb3-278a-7622-94b2-cae6d9a7522e/transitions/cancel-account-opening"));
    });

    test('should handle missing fields gracefully', () {
      final json = {
        "id": "test-id",
        "flow": "test-workflow",
        "extensions": {
          "currentState": "test-state",
          "status": "A"
        }
      };

      final snapshot = VNextInstanceSnapshot.fromInstanceJson(json);

      expect(snapshot.instanceId, equals("test-id"));
      expect(snapshot.workflowName, equals("test-workflow"));
      expect(snapshot.key, equals(""));
      expect(snapshot.domain, equals(""));
      expect(snapshot.flowVersion, equals(""));
      expect(snapshot.etag, equals(""));
      expect(snapshot.tags, equals([]));
      expect(snapshot.state, equals("test-state"));
      expect(snapshot.status, equals("A"));
      expect(snapshot.viewHref, isNull);
      expect(snapshot.loadData, equals(false));
      expect(snapshot.dataHref, isNull);
      expect(snapshot.transitions, equals([]));
      expect(snapshot.activeCorrelations, equals([]));
    });
  });
}

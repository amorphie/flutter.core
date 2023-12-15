/*
 * neo_core
 *
 * Created on 14/12/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum NeoNavigationType {
  @JsonValue('pop-until')
  popUntil,
  @JsonValue('push')
  push,
  @JsonValue('push-replacement')
  pushReplacement(),
  @JsonValue('push-as-root')
  pushAsRoot,
  @JsonValue('popup')
  popup,
  @JsonValue('bottom-sheet')
  bottomSheet;

  static const Map<String, NeoNavigationType> _jsonValues = {
    'pop-until': NeoNavigationType.popUntil,
    'push': NeoNavigationType.push,
    'push-replacement': NeoNavigationType.pushReplacement,
    'push-as-root': NeoNavigationType.pushAsRoot,
    'popup': NeoNavigationType.popup,
    'bottom-sheet': NeoNavigationType.bottomSheet,
  };

  static NeoNavigationType fromJson(String json) {
    return _jsonValues[json] ?? NeoNavigationType.pushReplacement;
  }
}

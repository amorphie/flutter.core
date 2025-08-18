/*
 * neo_core
 *
 * Created on 24/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum NeoErrorType {
  @JsonValue('popup')
  popup,
  @JsonValue('inline')
  inline,
  @JsonValue('invalid_token')
  invalidToken,
}

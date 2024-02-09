/*
 * neo_core
 *
 * Created on 9/2/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

enum NeoFeatureFlagKey {
  bypassSignalR("bypass-signalr");

  final String value;

  const NeoFeatureFlagKey(this.value);
}

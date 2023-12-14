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

import 'dart:convert';

import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';

class _Constant {
  static const keyNavigationPath = "navigationPath";
  static const keyNavigationType = "navigationType";
  static const keyPageId = "pageId";
  static const keyInitialData = "initialData";
}

class SignalrTransitionData {
  final String navigationPath;
  final NeoNavigationType navigationType;
  final String pageId;
  final Map<String, dynamic> initialData;

  SignalrTransitionData({
    required this.navigationPath,
    required this.navigationType,
    required this.pageId,
    required this.initialData,
  });

  String encode() {
    return jsonEncode({
      _Constant.keyNavigationPath: navigationPath,
      _Constant.keyNavigationType: navigationType.toString(),
      _Constant.keyPageId: pageId,
      _Constant.keyInitialData: initialData,
    });
  }

  factory SignalrTransitionData.decode(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return SignalrTransitionData(
      navigationPath: jsonMap[_Constant.keyNavigationPath],
      navigationType: NeoNavigationType.fromJson(jsonMap[_Constant.keyNavigationType]),
      pageId: jsonMap[_Constant.keyPageId],
      initialData: jsonMap[_Constant.keyInitialData],
    );
  }
}

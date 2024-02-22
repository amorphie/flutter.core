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

abstract class _Constant {
  static const keyNavigationPath = "navigationPath";
  static const keyNavigationType = "navigationType";
  static const keyPageId = "pageId";
  static const keyViewSource = "viewSource";
  static const keyInitialData = "initialData";
  static const keyIsBackNavigation = "isBackNavigation";
  static const keyTransitionId = "transitionId";
  static const keyStatusMessage = "statusMessage";
  static const keyStatusCode = "statusCode";
  static const statusCodeRedirectToLogin = "302";
}

class SignalrTransitionData {
  final String navigationPath;
  final NeoNavigationType navigationType;
  final String pageId;
  final String viewSource;
  final Map<String, dynamic> initialData;
  final bool isBackNavigation;
  final String transitionId;
  final String? statusMessage;
  final String? statusCode;

  SignalrTransitionData({
    required this.navigationPath,
    required this.navigationType,
    required this.pageId,
    required this.viewSource,
    required this.initialData,
    required this.isBackNavigation,
    required this.transitionId,
    this.statusMessage,
    this.statusCode,
  });

  String encode() {
    return jsonEncode({
      _Constant.keyNavigationPath: navigationPath,
      _Constant.keyNavigationType: navigationType.toString(),
      _Constant.keyPageId: pageId,
      _Constant.keyViewSource: viewSource,
      _Constant.keyInitialData: initialData,
      _Constant.keyIsBackNavigation: isBackNavigation,
      _Constant.keyTransitionId: transitionId,
      _Constant.keyStatusMessage: statusMessage,
      _Constant.keyStatusCode: statusCode,
    });
  }

  factory SignalrTransitionData.decode(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return SignalrTransitionData(
      navigationPath: jsonMap[_Constant.keyNavigationPath],
      navigationType: NeoNavigationType.fromJson(jsonMap[_Constant.keyNavigationType]),
      pageId: jsonMap[_Constant.keyPageId],
      viewSource: jsonMap[_Constant.keyViewSource],
      initialData: jsonMap[_Constant.keyInitialData],
      isBackNavigation: jsonMap[_Constant.keyIsBackNavigation],
      transitionId: jsonMap[_Constant.keyTransitionId],
      statusMessage: jsonMap[_Constant.keyStatusMessage],
      statusCode: jsonMap[_Constant.keyStatusCode],
    );
  }
}

extension NeoSignalRTransitionExtension on SignalrTransitionData {
  bool get shouldRedirectToLogin => statusCode == _Constant.statusCodeRedirectToLogin;
}

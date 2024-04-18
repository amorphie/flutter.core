import 'dart:convert';

class _Constant {
  static const keyFlowState = "transition";
  static const keyEkycState = "state";
  static const keyInitialData = "initialData";
}

class EkycEventData {
  final String flowState;
  final String ekycState;
  final Map<String, dynamic> initialData;

  EkycEventData({required this.flowState, required this.ekycState, required this.initialData});

  String encode() {
    return jsonEncode({
      _Constant.keyFlowState: flowState,
      _Constant.keyEkycState: ekycState,
      _Constant.keyInitialData: initialData,
    });
  }

  factory EkycEventData.decode(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return EkycEventData(
      flowState: jsonMap[_Constant.keyFlowState],
      ekycState: jsonMap[_Constant.keyEkycState],
      initialData: jsonMap[_Constant.keyInitialData],
    );
  }
}

import 'dart:convert';

class _Constant {
  static const keyFlowState = "state";
  static const keyEkycState = "state";
  static const keyMessage = "message";
}

class SignalrEkycData {
  final String state;
  final String ekycState;
  final String message;

  SignalrEkycData({required this.state, required this.ekycState, required this.message});

  String encode() {
    return jsonEncode({
      _Constant.keyFlowState: state,
      _Constant.keyEkycState: ekycState,
      _Constant.keyMessage: message,
    });
  }

  factory SignalrEkycData.decode(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return SignalrEkycData(
      state: jsonMap[_Constant.keyFlowState],
      ekycState: jsonMap[_Constant.keyEkycState],
      message: jsonMap[_Constant.keyMessage],
    );
  }
}
